import SwiftData
import Combine
import Foundation
import OSLog
import AsyncAlgorithms

@BackgroundActor
class SyncManager {

    private let logger = Logger(category: "SyncManager")
    private let database: Database
    private let syncServices: [any SyncService]
    private var cancellables: Set<AnyCancellable> = []
    
    /// Tracks whether a sync is currently in progress
    private var isSyncing = false
    /// Continuations waiting for sync to complete
    private var syncWaiters: [CheckedContinuation<Void, Never>] = []
    /// Queue of pending sync operations to prevent race conditions
    private var pendingSyncCount = 0

    init(database: Database, syncServices: [any SyncService]) {
        self.database = database
        self.syncServices = syncServices
        initialize()
    }

    private func initialize() {
        Task { [weak self, logger] in
            guard let self else { return }
            for service in syncServices {
                do {
                    let syncMode = await service.mode
                    let syncDate = Date.now
                    try await service.initialize(with: database)
                    let existingState: RawSyncServiceState?
                    do {
                        existingState = try await database.fetchSyncServiceState(for: service.identifier)
                    } catch DatabaseError.objectNotFound {
                        existingState = nil
                    }
                    var state = existingState ?? .init(id: service.identifier)
                    // Only call initiallySync when an existing disabled service is being re-enabled.
                    // For brand-new services (no prior state), processChanges handles the initial sync
                    // via history from .distantPast, avoiding a race with concurrent performSync() calls.
                    if existingState != nil, state.lastSyncMode == .disabled {
                        let syncStartDate: Date? = if case .enabledFrom(let date) = syncMode {
                            date
                        } else if syncMode == .enabled {
                            .distantPast
                        } else { nil }
                        if let syncStartDate {
                            try await initiallySync(service, from: syncStartDate, upTo: syncDate)
                            state.lastSyncDate = syncDate
                            state.lastSyncMode = syncMode
                        }
                    }
                    try await database.upsertSyncServiceState(state)
                    logger.info("Initialized sync service with identifier \"\(service.identifier)\"")
                } catch {
                    logger.error("Failed to initialize sync service with identifier \"\(service.identifier)\": \(error)")
                }
            }
            startStreamingChanges()
        }.store(in: &cancellables)
    }

    func initiallySync(_ service: any SyncService, from startDate: Date, upTo syncDate: Date) async throws {
        let workouts = try await database.fetchFinishedWorkouts(startingFrom: startDate)
        for workout in workouts {
            guard workout.source != .syncService(identifier: service.identifier) else { continue }
            var mapping = Self.serviceMapping(of: workout, for: service)
            
            // Skip if already synced or in conflict
            guard mapping.syncStatus != .synced && mapping.syncStatus != .conflict else { continue }
            
            do {
                (mapping.externalId, mapping.externalUrl) = try await service.insert(workout)
                mapping.syncStatus = .synced
                mapping.lastEditDateSynced = workout.lastEditDate
            } catch SyncError.serviceUnavailable {
                // If service is unavailable during initial sync, propagate error
                throw SyncError.serviceUnavailable
            } catch SyncError.conflict {
                mapping.syncStatus = .conflict
            } catch {
                mapping.syncStatus = .failed
                logger.error("Initial sync insert failed for workout \(workout.id): \(error)")
            }
            try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
        }
    }

    private func startStreamingChanges() {
        Task { [weak self, logger] in
            do {
                logger.info("Started streaming workout changes")
                let didSaveSequence = NotificationCenter.default.notifications(named: ModelContext.didSave)
                for await _ in didSaveSequence.buffer(policy: .bufferingLatest(1)) where !Task.isCancelled {
                    guard let self else { return }
                    let syncDate = Date.now
                    for service in syncServices {
                        try await sync(service, upTo: syncDate)
                    }
                }
            } catch {
                logger.fault("Failed streaming history with error: \(error)")
            }
        }
    }

    func performSync(upTo syncDate: Date = .now) async throws {
        // Wait for any ongoing sync to complete, then perform sync
        try await withSyncLock {
            for service in syncServices {
                try await sync(service, upTo: syncDate)
            }
        }
    }
    
    /// Performs a user-initiated sync. Waits for any ongoing sync to complete first.
    func performUserInitiatedSync(upTo syncDate: Date = .now) async throws {
        // This method has the same behavior as performSync but is explicitly named
        // for user-initiated actions. The withSyncLock ensures proper serialization.
        try await performSync(upTo: syncDate)
    }
    
    /// Ensures only one sync operation runs at a time
    private func withSyncLock<T>(_ operation: () async throws -> T) async rethrows -> T {
        // Increment pending count and wait if already syncing
        pendingSyncCount += 1
        defer { pendingSyncCount -= 1 }
        
        if isSyncing {
            await withCheckedContinuation { continuation in
                syncWaiters.append(continuation)
            }
        }
        
        // Mark as syncing and perform operation
        isSyncing = true
        defer {
            // Only release the lock if no more pending operations
            if pendingSyncCount <= 1 {
                isSyncing = false
                // Resume all waiting continuations
                let waiters = syncWaiters
                syncWaiters.removeAll()
                for waiter in waiters {
                    waiter.resume()
                }
            } else if let nextWaiter = syncWaiters.first {
                // Resume only the next waiter in queue
                syncWaiters.removeFirst()
                nextWaiter.resume()
            }
        }
        
        return try await operation()
    }

    private func sync(_ service: any SyncService, upTo syncDate: Date) async throws {
        let syncMode = await service.mode
        do {
            let state = try await database.fetchSyncServiceState(for: service.identifier)
            switch syncMode {
            case .enabled, .enabledFrom:
                do {
                    try await processChanges(for: service, with: state, and: syncMode, upTo: syncDate)
                } catch SyncError.serviceUnavailable {
                    logger.warning("Service \"\(service.identifier)\" is unavailable. Will retry on next sync.")
                    // Don't throw - just log and continue to next service
                }
            case .disabled:
                // TODO: delete state
                break
            }
        } catch DatabaseError.objectNotFound {
            switch syncMode {
            case .enabled, .enabledFrom:
                let state = RawSyncServiceState(id: service.identifier, preferences: [:])
                do {
                    try await processChanges(for: service, with: state, and: syncMode, upTo: syncDate)
                } catch SyncError.serviceUnavailable {
                    logger.warning("Service \"\(service.identifier)\" is unavailable. Will retry on next sync.")
                    // Don't throw - just log and continue to next service
                }
            case .disabled:
                break
            }
        }
    }

    private func processChanges(
        for service: any SyncService,
        with syncState: RawSyncServiceState,
        and syncMode: SyncMode,
        upTo syncDate: Date
    ) async throws {
        let lastSyncDate = syncState.lastSyncDate ?? .distantPast
        let relevantAttributes = service.relevantAttributes
        let history = try await database.fetchHistory(in: lastSyncDate..<syncDate)
        
        // Also retry any previously failed or pending syncs
        let retriableWorkouts = try await fetchRetriableWorkouts(for: service)
        
        var inserted: Int = 0, updated: Int = 0, deleted: Int = 0
        var serviceUnavailable = false
        
        // First, retry previously failed/pending workouts
        for workout in retriableWorkouts {
            if serviceUnavailable { break }
            
            var mapping = Self.serviceMapping(of: workout, for: service)
            
            // Skip workouts in conflict state - they require manual intervention
            guard mapping.syncStatus != .conflict else { continue }
            
            do {
                (mapping.externalId, mapping.externalUrl) = try await service.insert(workout)
                mapping.syncStatus = .synced
                mapping.lastEditDateSynced = workout.lastEditDate
                inserted += 1
                try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
            } catch SyncError.serviceUnavailable {
                serviceUnavailable = true
                throw SyncError.serviceUnavailable
            } catch SyncError.conflict {
                mapping.syncStatus = .conflict
                try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
            } catch {
                mapping.syncStatus = .failed
                logger.error("Retry sync failed for workout \(workout.id): \(error)")
                try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
            }
        }
        
        guard !history.isEmpty else {
            // Update state even if no history, to track that we checked for retries
            if inserted > 0 {
                var updatedState = syncState
                updatedState.lastSyncDate = syncDate
                updatedState.lastSyncMode = syncMode
                try await database.upsertSyncServiceState(updatedState)
                logger.info("Processed retries for sync service \"\(service.identifier)\" (\(inserted) inserted).")
            }
            return
        }
        
        for transaction in history {
            if serviceUnavailable { break }
            
            for change in transaction.changes {
                if serviceUnavailable { break }
                
                switch change {
                case let .insert(insert):
                    guard let insert = insert as? any HistoryInsert<Workout> else { continue }
                    
                    // Try to fetch the workout - if it was deleted, skip this history entry
                    let workout: RawWorkout
                    do {
                        workout = try await database.fetchWorkout(for: insert.changedPersistentIdentifier)
                    } catch DatabaseError.objectNotFound {
                        // Workout was deleted before sync completed - skip it
                        continue
                    }
                    
                    guard workout.source != .syncService(identifier: service.identifier) else { continue }
                    var mapping = Self.serviceMapping(of: workout, for: service)
                    
                    // Skip if already synced or in conflict
                    guard mapping.syncStatus != .synced && mapping.syncStatus != .conflict else { continue }
                    
                    do {
                        (mapping.externalId, mapping.externalUrl) = try await service.insert(workout)
                        mapping.syncStatus = .synced
                        mapping.lastEditDateSynced = workout.lastEditDate
                        inserted += 1
                    } catch SyncError.serviceUnavailable {
                        serviceUnavailable = true
                        throw SyncError.serviceUnavailable
                    } catch SyncError.conflict {
                        mapping.syncStatus = .conflict
                    } catch {
                        mapping.syncStatus = .failed
                        logger.error("Insert sync failed for workout \(workout.id): \(error)")
                    }
                    try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)

                case let .update(update):
                    guard let update = update as? any HistoryUpdate<Workout> else { continue }
                    
                    // Try to fetch the workout - if it was deleted, skip this history entry
                    let workout: RawWorkout
                    do {
                        workout = try await database.fetchWorkout(for: update.changedPersistentIdentifier)
                    } catch DatabaseError.objectNotFound {
                        // Workout was deleted before sync completed - skip it
                        continue
                    }
                    
                    guard workout.source != .syncService(identifier: service.identifier) else { continue }
                    var mapping = Self.serviceMapping(of: workout, for: service)
                    
                    // Skip workouts in conflict state
                    guard mapping.syncStatus != .conflict else { continue }
                    
                    if workout.endDate == nil {
                        // Workout is now in progress, delete from service
                        do {
                            try await service.delete(workoutWith: workout.id)
                            mapping.externalId = nil
                            mapping.externalUrl = nil
                            mapping.lastEditDateSynced = nil
                            mapping.syncStatus = .pending
                            deleted += 1
                        } catch SyncError.serviceUnavailable {
                            serviceUnavailable = true
                            throw SyncError.serviceUnavailable
                        } catch SyncError.conflict {
                            mapping.syncStatus = .conflict
                        } catch {
                            mapping.syncStatus = .failed
                            logger.error("Delete sync (from update) failed for workout \(workout.id): \(error)")
                        }
                        try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
                    } else if !Set(update.updatedAttributes).intersection(relevantAttributes).isEmpty {
                        // Only sync if relevant attributes changed
                        do {
                            (mapping.externalId, mapping.externalUrl) = try await service.update(workout)
                            mapping.syncStatus = .synced
                            mapping.lastEditDateSynced = workout.lastEditDate
                            updated += 1
                        } catch SyncError.serviceUnavailable {
                            serviceUnavailable = true
                            throw SyncError.serviceUnavailable
                        } catch SyncError.conflict {
                            mapping.syncStatus = .conflict
                        } catch {
                            mapping.syncStatus = .failed
                            logger.error("Update sync failed for workout \(workout.id): \(error)")
                        }
                        try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
                    }

                case let .delete(delete):
                    guard let delete = delete as? any HistoryDelete<Workout> else { continue }
                    if let id = delete.tombstone[\.id] as? UUID {
                        do {
                            try await service.delete(workoutWith: id)
                            deleted += 1
                        } catch SyncError.serviceUnavailable {
                            serviceUnavailable = true
                            throw SyncError.serviceUnavailable
                        } catch SyncError.conflict {
                            logger.error("Delete conflict for workout \(id) on service \"\(service.identifier)\"")
                        } catch {
                            logger.error("Delete sync failed for workout \(id): \(error)")
                        }
                    } else {
                        logger.fault("Deleted workout has no id: \(String(describing: delete.changedPersistentIdentifier))")
                    }

                @unknown default:
                    logger.fault("Unknown transaction change.")
                }
            }
        }
        // Only persist state update when actual workout changes were synced.
        // This prevents cascading saves triggered by mapping/state persistence.
        guard inserted > 0 || updated > 0 || deleted > 0 else { return }
        var updatedState = syncState
        updatedState.lastSyncDate = syncDate
        updatedState.lastSyncMode = syncMode
        try await database.upsertSyncServiceState(updatedState)
        logger.info("Processed changes for sync service \"\(service.identifier)\" (\(inserted) inserted, \(updated) updated, \(deleted) deleted).")
    }
    
    /// Fetches workouts that have failed or pending sync status for retry
    private func fetchRetriableWorkouts(for service: any SyncService) async throws -> [RawWorkout] {
        try await database.fetchRetriableWorkouts(for: service.identifier)
    }

    private static func serviceMapping(of workout: RawWorkout, for service: any SyncService) -> RawSyncServiceMapping {
        if let mapping = workout.serviceMappings.first(where: { $0.serviceIdentifier == service.identifier }) {
            mapping
        } else {
            .init(serviceIdentifier: service.identifier)
        }
    }
}
