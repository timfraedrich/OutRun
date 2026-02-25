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
                    var state: RawSyncServiceState
                    do {
                        state = try await database.fetchSyncServiceState(for: service.identifier)
                    } catch DatabaseError.objectNotFound {
                        state = .init(id: service.identifier)
                    }
                    try await service.initialize(with: database)
                    let syncStartDate: Date? = if case .enabledFrom(let date) = syncMode {
                        date
                    } else if syncMode == .enabled {
                        .distantPast
                    } else { nil }
                    if state.lastSyncMode == .disabled, let syncStartDate {
                        try await initiallySync(service, from: syncStartDate, upTo: syncDate)
                        state.lastSyncDate = syncDate
                        state.lastSyncMode = syncMode
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
            do {
                (mapping.externalId, mapping.externalUrl) = try await service.insert(workout)
                mapping.syncStatus = .synced
                mapping.lastEditDateSynced = workout.lastEditDate
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
        for service in syncServices {
            try await sync(service, upTo: syncDate)
        }
    }

    private func sync(_ service: any SyncService, upTo syncDate: Date) async throws {
        let syncMode = await service.mode
        do {
            let state = try await database.fetchSyncServiceState(for: service.identifier)
            switch syncMode {
            case .enabled, .enabledFrom:
                try await processChanges(for: service, with: state, and: syncMode, upTo: syncDate)
            case .disabled:
                // TODO: delete state
                break
            }
        } catch DatabaseError.objectNotFound {
            switch syncMode {
            case .enabled, .enabledFrom:
                let state = RawSyncServiceState(id: service.identifier, preferences: [:])
                try await processChanges(for: service, with: state, and: syncMode, upTo: syncDate)
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
        guard !history.isEmpty else { return }
        var inserted: Int = 0, updated: Int = 0, deleted: Int = 0
        for transaction in history {
            for change in transaction.changes {
                switch change {
                case let .insert(insert):
                    guard let insert = insert as? any HistoryInsert<Workout> else { continue }
                    let workout = try await database.fetchWorkout(for: insert.changedPersistentIdentifier)
                    guard workout.source != .syncService(identifier: service.identifier) else { continue }
                    var mapping = Self.serviceMapping(of: workout, for: service)
                    do {
                        (mapping.externalId, mapping.externalUrl) = try await service.insert(workout)
                        mapping.syncStatus = .synced
                        mapping.lastEditDateSynced = workout.lastEditDate
                        inserted += 1
                    } catch SyncError.conflict {
                        mapping.syncStatus = .conflict
                    } catch {
                        mapping.syncStatus = .failed
                        logger.error("Insert sync failed for workout \(workout.id): \(error)")
                    }
                    try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)

                case let .update(update):
                    guard let update = update as? any HistoryUpdate<Workout> else { continue }
                    let workout = try await database.fetchWorkout(for: update.changedPersistentIdentifier)
                    guard workout.source != .syncService(identifier: service.identifier) else { continue }
                    var mapping = Self.serviceMapping(of: workout, for: service)
                    if workout.endDate == nil {
                        do {
                            try await service.delete(workoutWith: workout.id)
                            mapping.externalId = nil
                            mapping.externalUrl = nil
                            mapping.lastEditDateSynced = nil
                            mapping.syncStatus = .pending
                            deleted += 1
                        } catch SyncError.conflict {
                            mapping.syncStatus = .conflict
                        } catch {
                            mapping.syncStatus = .failed
                            logger.error("Delete sync (from update) failed for workout \(workout.id): \(error)")
                        }
                        try await database.upsertSyncServiceMapping(mapping, forWorkoutWith: workout.id)
                    } else if !Set(update.updatedAttributes).intersection(relevantAttributes).isEmpty {
                        do {
                            (mapping.externalId, mapping.externalUrl) = try await service.update(workout)
                            mapping.syncStatus = .synced
                            mapping.lastEditDateSynced = workout.lastEditDate
                            updated += 1
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

    private static func serviceMapping(of workout: RawWorkout, for service: any SyncService) -> RawSyncServiceMapping {
        if let mapping = workout.serviceMappings.first(where: { $0.serviceIdentifier == service.identifier }) {
            mapping
        } else {
            .init(serviceIdentifier: service.identifier)
        }
    }
}
