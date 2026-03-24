import SwiftData
import Combine
import Foundation
import OSLog
import AsyncAlgorithms

@BackgroundActor
class SyncManager {

    private let logger = Logger(category: "SyncManager")
    private let database: Database
    private let syncDelegate: any SyncDelegate
    private let syncServices: [any SyncService]
    private var cancellables: Set<AnyCancellable> = []
    
    /// Tracks whether a sync is currently in progress
    private var isSyncing = false
    /// Continuations waiting for sync to complete
    private var syncWaiters: [CheckedContinuation<Void, Never>] = []
    /// Queue of pending sync operations to prevent race conditions
    private var pendingSyncCount = 0

    init(database: Database, syncDelegate: any SyncDelegate, syncServices: [any SyncService]) {
        self.database = database
        self.syncDelegate = syncDelegate
        self.syncServices = syncServices
    }

    func initialize() async {
        for service in syncServices {
            do {
                let syncMode = await service.mode
                let syncDate = Date.now
                try await service.initialize(with: syncDelegate)
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
                logger.fault("Failed to initialize sync service with identifier \"\(service.identifier)\": \(error)")
            }
        }
        startStreamingChanges()
    }
    
    func deinitialize() async {
        for service in syncServices {
            await service.deinitialize()
            logger.info("Deinitialized sync service with identifier \"\(service.identifier)\"")
        }
    }

    func initiallySync(_ service: any SyncService, from startDate: Date, upTo syncDate: Date) async throws {
        let workouts = try await database.fetchFinishedWorkouts(startingFrom: startDate)
        for workout in workouts {
            guard workout.source != .syncService(identifier: service.identifier) else { continue }
            var mapping = Self.serviceMapping(of: workout, for: service)
            
            // Skip if already synced or in conflict
            guard mapping.syncStatus != .synced && mapping.syncStatus != .conflict else { continue }
            
            do {
                (mapping.externalId, mapping.externalUrl) = try await service.upsert(workout)
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
                try await self?.syncAllServices()
                let didSaveSequence = NotificationCenter.default.notifications(named: ModelContext.didSave)
                    .buffer(policy: .bufferingLatest(1))
                for await _ in didSaveSequence where !Task.isCancelled {
                    guard let self else { return }
                    try await syncAllServices()
                }
            } catch {
                logger.fault("Failed streaming history with error: \(error)")
            }
        }
    }
    
    private func syncAllServices(upTo syncDate: Date = .now) async throws {
        let syncDate = Date.now
        for service in syncServices {
            try await sync(service, upTo: syncDate)
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

    // MARK: - Change Processing

    private func processChanges(
        for service: any SyncService,
        with syncState: RawSyncServiceState,
        and syncMode: SyncMode,
        upTo syncDate: Date
    ) async throws {
        let lastSyncDate = syncState.lastSyncDate ?? .distantPast
        let summaries = try await aggregateHistory(in: lastSyncDate..<syncDate, relevantAttributes: service.relevantAttributes)
        var counts = SyncCounts()
        var processedWorkoutIds = Set<UUID>()
        for (persistentId, summary) in summaries {
            try await processSummary(
                summary,
                persistentId: persistentId,
                service: service,
                counts: &counts,
                processedWorkoutIds: &processedWorkoutIds
            )
        }
        try await retryPendingWorkouts(
            for: service,
            excluding: processedWorkoutIds,
            counts: &counts
        )
        guard counts.hasChanges else { return }
        var updatedState = syncState
        updatedState.lastSyncDate = syncDate
        updatedState.lastSyncMode = syncMode
        try await database.upsertSyncServiceState(updatedState)
        logger.info("Processed changes for sync service \"\(service.identifier)\" (\(counts.upserted) upserted, \(counts.deleted) deleted).")
    }

    /// Scans history transactions and reduces them to one `WorkoutChangeSummary` per workout.
    private func aggregateHistory(
        in dateRange: Range<Date>,
        relevantAttributes: Set<PartialKeyPath<Workout> & Sendable>
    ) async throws -> [PersistentIdentifier: WorkoutChangeSummary] {
        var summaries: [PersistentIdentifier: WorkoutChangeSummary] = [:]
        let history = try await database.fetchHistory(in: dateRange)
        for transaction in history {
            for change in transaction.changes {
                switch change {
                case let .insert(insert):
                    guard insert is any HistoryInsert<Workout> else { continue }
                    summaries[insert.changedPersistentIdentifier, default: .init()].wasInserted = true
                    // If a workout is inserted again after being deleted the delete information should be removed from the summary.
                    if summaries[insert.changedPersistentIdentifier, default: .init()].wasDeleted {
                        summaries[insert.changedPersistentIdentifier, default: .init()].wasDeleted = false
                        summaries[insert.changedPersistentIdentifier, default: .init()].tombstoneId = nil
                        summaries[insert.changedPersistentIdentifier, default: .init()].tombstoneSource = nil
                    }
                case let .update(update):
                    guard let update = update as? any HistoryUpdate<Workout> else { continue }
                    guard !Set(update.updatedAttributes).intersection(relevantAttributes).isEmpty else { continue }
                    summaries[update.changedPersistentIdentifier, default: .init()].hadRelevantUpdate = true
                case let .delete(delete):
                    guard let delete = delete as? any HistoryDelete<Workout> else { continue }
                    let persistentIdentifier = delete.changedPersistentIdentifier
                    summaries[persistentIdentifier, default: .init()].wasDeleted = true
                    summaries[persistentIdentifier, default: .init()].tombstoneId = delete.tombstone[\.id] as? UUID
                    summaries[persistentIdentifier, default: .init()].tombstoneSource = delete.tombstone[\.rawSource] as? String
                @unknown default:
                    logger.fault("Unknown transaction change.")
                }
            }
        }
        return summaries
    }

    /// Executes the appropriate service call for a single workout's aggregated change summary.
    private func processSummary(
        _ summary: WorkoutChangeSummary,
        persistentId: PersistentIdentifier,
        service: any SyncService,
        counts: inout SyncCounts,
        processedWorkoutIds: inout Set<UUID>
    ) async throws {
        if summary.wasDeleted {
            guard let id = summary.tombstoneId else {
                logger.fault("Deleted workout has no id tombstone for persistent identifier \(String(describing: persistentId))")
                return
            }
            processedWorkoutIds.insert(id)
            try await processDeletedWorkout(id: id, summary: summary, service: service, counts: &counts)
            
        } else {
            let workout: RawWorkout
            do {
                workout = try await database.fetchWorkout(for: persistentId)
            } catch DatabaseError.objectNotFound {
                return
            }
            processedWorkoutIds.insert(workout.id)
            try await processExistingWorkout(workout, summary: summary, service: service, counts: &counts)
        }
    }

    /// Handles the service call for a workout that was deleted from the DB in this window.
    private func processDeletedWorkout(
        id: UUID,
        summary: WorkoutChangeSummary,
        service: any SyncService,
        counts: inout SyncCounts
    ) async throws {
        // Skip workouts that originated from this service to avoid sync loops.
        if let rawSource = summary.tombstoneSource, WorkoutSource(rawValue: rawSource) == .syncService(identifier: service.identifier) {
            return
        }
        // A workout created and deleted in the same window was never on the service.
        guard !summary.wasInserted else { return }
        // Otherwise attempt the delete. The service must treat "not found" as a no-op.
        do {
            try await service.delete(workoutWith: id)
            counts.deleted += 1
        } catch SyncError.serviceUnavailable {
            throw SyncError.serviceUnavailable
        } catch {
            logger.error("Delete sync failed for workout \(id) on service \"\(service.identifier)\": \(error)")
        }
    }

    /// Determines and executes the appropriate service call for a workout that still exists.
    private func processExistingWorkout(
        _ workout: RawWorkout,
        summary: WorkoutChangeSummary,
        service: any SyncService,
        counts: inout SyncCounts
    ) async throws {
        guard workout.source != .syncService(identifier: service.identifier) else { return }
        var mapping = Self.serviceMapping(of: workout, for: service)
        let syncStatus = mapping.syncStatus
        // guard syncStatus != .conflict else { return }
        
        let action: SyncAction = switch syncStatus {
        case .synced:
            if workout.endDate == nil {
                .delete
            } else if summary.hadRelevantUpdate {
                .upsert
            } else {
                .none
            }
        case .pending, .failed:
            if workout.endDate == nil {
                .none
            } else if summary.wasInserted || summary.hadRelevantUpdate {
                .upsert
            } else {
                .none
            }
        case .conflict, .unknown:
            .none
        }
        guard action != .none else { return }
        do {
            try await execute(action, for: workout, mapping: &mapping, service: service, counts: &counts)
        } catch SyncError.serviceUnavailable {
            throw SyncError.serviceUnavailable
        } catch SyncError.conflict {
            mapping.syncStatus = .conflict
        } catch {
            mapping.syncStatus = .failed
            logger.error("\(action) sync failed for workout \(workout.id): \(error)")
        }
        try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
    }

    /// Retries finished workouts with pending/failed mappings that had no history events in this window.
    private func retryPendingWorkouts(
        for service: any SyncService,
        excluding processedIds: Set<UUID>,
        counts: inout SyncCounts
    ) async throws {
        let retriableWorkouts = try await database.fetchRetriableWorkouts(for: service.identifier)
        for workout in retriableWorkouts {
            guard !processedIds.contains(workout.id) else { continue }

            var mapping = Self.serviceMapping(of: workout, for: service)
            guard mapping.syncStatus == .pending || mapping.syncStatus == .failed else { continue }

            do {
                try await execute(.upsert, for: workout, mapping: &mapping, service: service, counts: &counts)
            } catch SyncError.serviceUnavailable {
                throw SyncError.serviceUnavailable
            } catch SyncError.conflict {
                mapping.syncStatus = .conflict
            } catch {
                mapping.syncStatus = .failed
                logger.error("Retry insert failed for workout \(workout.id): \(error)")
            }
            try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
        }
    }

    /// Executes a sync action against the service and updates the mapping accordingly.
    private func execute(
        _ action: SyncAction,
        for workout: RawWorkout,
        mapping: inout RawSyncServiceMapping,
        service: any SyncService,
        counts: inout SyncCounts
    ) async throws {
        switch action {
        case .none:
            break
        case .upsert:
            (mapping.externalId, mapping.externalUrl) = try await service.upsert(workout)
            mapping.syncStatus = .synced
            mapping.lastEditDateSynced = workout.lastEditDate
            counts.upserted += 1
        case .delete:
            try await service.delete(workoutWith: workout.id)
            mapping.externalId = nil
            mapping.externalUrl = nil
            mapping.lastEditDateSynced = nil
            mapping.syncStatus = .pending
            counts.deleted += 1
        }
    }

    // MARK: - Helpers

    private static func serviceMapping(of workout: RawWorkout, for service: any SyncService) -> RawSyncServiceMapping {
        if let mapping = workout.serviceMappings.first(where: { $0.serviceIdentifier == service.identifier }) {
            mapping
        } else {
            .init(serviceIdentifier: service.identifier)
        }
    }
}

// MARK: - Supporting types

/// Aggregated description of what happened to a single workout across all history events in a sync window.
///
/// Rather than evaluating each history event individually against live DB state (which is incorrect
/// since the live state reflects the final state, not the state at each event's time), all events
/// are reduced to this summary. The correct service action is then derived from the pre-window
/// mapping status combined with the current DB state.
private struct WorkoutChangeSummary {
    /// True if the workout was inserted in this window (i.e. it is new to the DB).
    var wasInserted: Bool = false
    /// True if the workout was deleted in this window (i.e. it is new to the DB).
    var wasDeleted: Bool = false
    /// True if any non-`endDate` attribute that the service cares about was changed.
    var hadRelevantUpdate: Bool = false
    /// UUID from the delete tombstone, tombstone != nil indicates that the workout was deleted from the DB during this window.
    var tombstoneId: UUID? = nil
    /// Source raw value from the delete tombstone (only valid when `wasDeleted == true`).
    var tombstoneSource: String? = nil
}

private enum SyncAction: Hashable, CustomStringConvertible {
    
    case none, upsert, delete
    
    var description: String {
        switch self {
        case .none: "None"
        case .upsert: "Upsert"
        case .delete: "Delete"
        }
    }
}

private struct SyncCounts {
    var upserted: Int = 0
    var deleted: Int = 0

    var hasChanges: Bool { upserted > 0 || deleted > 0 }
}
