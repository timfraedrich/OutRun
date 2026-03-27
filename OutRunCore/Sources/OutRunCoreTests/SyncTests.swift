import Foundation
@testable import OutRunCore
import Testing

@Suite("Sync Tests")
struct SyncTests {

    // MARK: - Helpers

    private func makeWorkout(
        name: String? = nil,
        comment: String? = nil,
        source: WorkoutSource = .native
    ) -> RawWorkout {
        let now = Date.now
        return RawWorkout(
            id: .init(),
            type: .running,
            distance: 1000,
            startDate: now.addingTimeInterval(-3600),
            endDate: now,
            energy: nil,
            repetitions: nil,
            isRace: false,
            name: name,
            comment: comment,
            creationDate: now,
            lastEditDate: now,
            source: source
        )
    }

    // MARK: - Outbound Sync (Core → Service)

    @Test("Insert triggers service upsert")
    func insertTriggersSyncServiceInsert() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService()

        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.count == 1)
        #expect(upserted.first?.value.id == workout.id)
    }

    @Test("Update of relevant attribute triggers service upsert")
    func updateOfRelevantAttributeTriggersSyncServiceUpdate() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(name: "original")
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService(relevantAttributes: [\.name])
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        let workouts = try await database.fetchWorkouts()
        guard var modifiedWorkout = workouts.first else { throw "No workout found after insert." }
        modifiedWorkout.name = "updated"
        _ = try await database.upsert(modifiedWorkout)

        try await syncManager.performSync()

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.count == 1)
        #expect(upserted.first?.value.name == "updated")
    }

    @Test("Update of irrelevant attribute does not trigger service upsert")
    func updateOfIrrelevantAttributeDoesNotTriggerSyncServiceUpdate() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(name: "original")
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        // relevantAttributes watches only \.name, but we change comment
        let mockService = MockSyncService(relevantAttributes: [\.name])
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()
        // Clear ids after insert
        await mockService.reset()
        
        let workouts = try await database.fetchWorkouts()
        guard var modifiedWorkout = workouts.first else { throw "No workout found after insert." }
        modifiedWorkout.comment = "new comment"
        _ = try await database.upsert(modifiedWorkout)

        try await syncManager.performSync()

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.isEmpty)
    }

    @Test("Delete triggers service delete")
    func deleteTriggersSyncServiceDelete() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        try await database.delete(workoutWithIdentifier: workout.id)
        try await syncManager.performSync()

        let deletedIds = await mockService.deletedWorkoutIds
        #expect(deletedIds.contains(workout.id))
    }

    @Test("Workout from same sync service is not re-synced outbound")
    func workoutFromSameSyncServiceIsNotReSyncedOutbound() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .syncService(identifier: "mock"))
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService(identifier: "mock")
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.isEmpty)
    }

    @Test("Workout from different sync service is not synced outbound")
    func workoutFromDifferentSyncServiceIsSyncedOutbound() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .syncService(identifier: "other-service"))
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService(identifier: "mock")
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.isEmpty)
    }

    @Test("Successful upsert persists synced mapping with external ID")
    func successfulInsertPersistsSyncedMappingWithExternalId() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        let workouts = try await database.fetchWorkouts()
        let mapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "mock" })
        #expect(mapping?.syncStatus == .synced)
        #expect(mapping?.externalId == "mock-external-id")
    }

    @Test("Failed upsert persists failed mapping")
    func failedInsertPersistsFailedMapping() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService(upsertError: NSError(domain: "test", code: 1))
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        let workouts = try await database.fetchWorkouts()
        let mapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "mock" })
        #expect(mapping?.syncStatus == .failed)
    }

    @Test("Service unavailable error skips remaining changes for that service")
    func serviceUnavailableErrorSkipsRemainingChanges() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout1 = makeWorkout(name: "workout1")
        let workout2 = makeWorkout(name: "workout2")
        try await database.insert(workout1)
        try await database.insert(workout2)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService(upsertError: SyncError.serviceUnavailable)
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        let upserted = await mockService.upsertedWorkouts
        // First workout should trigger the error, second should not be attempted
        #expect(upserted.count == 0)
    }

    @Test("Conflict status prevents future automatic syncs")
    func conflictStatusPreventsFutureAutomaticSyncs() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(name: "original")
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService(upsertError: SyncError.conflict)
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        // Verify conflict status is set
        let workouts = try await database.fetchWorkouts()
        let mapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "mock" })
        #expect(mapping?.syncStatus == .conflict)

        // Now update the workout
        guard var modifiedWorkout = workouts.first else { throw "No workout found" }
        modifiedWorkout.name = "updated"
        _ = try await database.upsert(modifiedWorkout)

        // Clear the mock's state
        await mockService.reset()
        
        // Perform another sync - the workout should NOT be synced because it has conflict status
        try await syncManager.performSync()

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.isEmpty, "Workout with conflict status should not be automatically synced")
    }

    @Test("Failed status allows retry on next sync")
    func failedStatusAllowsRetryOnNextSync() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService(upsertError: NSError(domain: "test", code: 1))
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.performSync()

        // Verify failed status
        var workouts = try await database.fetchWorkouts()
        var mapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "mock" })
        #expect(mapping?.syncStatus == .failed)

        // Now clear the error and try again
        await mockService.clearError()
        try await syncManager.performSync()

        // Should have retried and succeeded
        workouts = try await database.fetchWorkouts()
        mapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "mock" })
        #expect(mapping?.syncStatus == .synced)
    }

    // MARK: - Inbound Sync (Service → Core via SyncDelegate)

    @Test("SyncDelegate insert persists workout and returns its ID")
    func syncDelegateInsertPersistsWorkoutAndReturnsItsId() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        let delegate = await MockSyncDelegate(database: database)

        let returnedId = try await delegate.upsert(workout)

        #expect(returnedId == workout.id)
        let workouts = try await database.fetchWorkouts()
        #expect(workouts.contains(where: { $0.id == workout.id }))
    }

    @Test("SyncDelegate update modifies existing workout")
    func syncDelegateUpdateModifiesExistingWorkout() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(name: "original")
        let delegate = await MockSyncDelegate(database: database)
        _ = try await delegate.upsert(workout)

        var modified = workout
        modified.name = "updated"
        _ = try await delegate.upsert(modified)

        let workouts = try await database.fetchWorkouts()
        #expect(workouts.first?.name == "updated")
    }

    @Test("SyncDelegate delete removes workout from database")
    func syncDelegateDeleteRemovesWorkoutFromDatabase() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        let delegate = await MockSyncDelegate(database: database)
        _ = try await delegate.upsert(workout)

        try await delegate.delete(workoutWithIdentifier: workout.id)

        let workouts = try await database.fetchWorkouts()
        #expect(workouts.isEmpty)
    }

    // MARK: - Initial Sync

    @Test("initiallySync propagates existing workouts to service")
    func initiallySyncPropagatesExistingWorkoutsToService() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .native)
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.initiallySync(mockService, from: .distantPast, upTo: .now)

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.count == 1)
        #expect(upserted.first?.key == workout.id)
    }

    @Test("initiallySync skips workouts from same sync service")
    func initiallySyncSkipsWorkoutsFromSameSyncService() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .syncService(identifier: "mock"))
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService(identifier: "mock")
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        try await syncManager.initiallySync(mockService, from: .distantPast, upTo: .now)

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.isEmpty)
    }

    @Test("initiallySync respects startDate filter")
    func initiallySyncRespectsStartDateFilter() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        // Workout started 48h ago, should be excluded if startDate is 24h ago
        let now = Date.now
        let oldWorkout = RawWorkout(
            id: .init(),
            type: .running,
            distance: 1000,
            startDate: now.addingTimeInterval(-48 * 3600),
            endDate: now.addingTimeInterval(-47 * 3600),
            energy: nil,
            repetitions: nil,
            isRace: false,
            name: nil,
            comment: nil,
            creationDate: now,
            lastEditDate: now,
            source: .native
        )
        try await database.insert(oldWorkout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        // Only sync workouts starting from 24h ago
        try await syncManager.initiallySync(mockService, from: now.addingTimeInterval(-24 * 3600), upTo: now)

        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.isEmpty)
    }

    // MARK: - User-Initiated Sync

    @Test("User-initiated sync waits for ongoing sync")
    func userInitiatedSyncWaitsForOngoingSync() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [mockService])
        
        // Start a sync but don't await it
        let firstSyncTask = Task {
            try await syncManager.performSync()
        }
        
        // Immediately start a user-initiated sync
        let userSyncTask = Task {
            try await syncManager.performUserInitiatedSync()
        }
        
        // Both should complete successfully
        _ = try await firstSyncTask.value
        _ = try await userSyncTask.value
        
        // The workout should be synced
        let upserted = await mockService.upsertedWorkouts
        #expect(upserted.count == 1)
    }

    // MARK: - Multiple Services

    @Test("One service failure does not affect other services")
    func oneServiceFailureDoesNotAffectOtherServices() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockSyncDelegate = await MockSyncDelegate(database: database)
        let failingService = MockSyncService(identifier: "failing", upsertError: SyncError.serviceUnavailable)
        let workingService = MockSyncService(identifier: "working")
        let syncManager = await SyncManager(database: database, syncDelegate: mockSyncDelegate, syncServices: [failingService, workingService])
        
        try await syncManager.performSync()

        // Working service should have synced successfully
        let workingUpserted = await workingService.upsertedWorkouts
        #expect(workingUpserted.count == 1)
        
        // Failing service should have failed
        let failingUpserted = await failingService.upsertedWorkouts
        #expect(failingUpserted.count == 0)
        
        // Check mappings
        let workouts = try await database.fetchWorkouts()
        let workingMapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "working" })
        #expect(workingMapping?.syncStatus == .synced)
    }
}
