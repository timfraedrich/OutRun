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

    @Test("Insert triggers service insert")
    func insertTriggersSyncServiceInsert() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        let inserted = await mockService.insertedWorkouts
        #expect(inserted.count == 1)
        #expect(inserted.first?.value.id == workout.id)
    }

    @Test("Update of relevant attribute triggers service update")
    func updateOfRelevantAttributeTriggersSyncServiceUpdate() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(name: "original")
        try await database.insert(workout)

        let mockService = MockSyncService(relevantAttributes: [\.name])
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        let workouts = try await database.fetchWorkouts()
        guard var modifiedWorkout = workouts.first else { throw "No workout found after insert." }
        modifiedWorkout.name = "updated"
        _ = try await database.update(modifiedWorkout)

        try await syncManager.performSync()

        let updated = await mockService.updatedWorkouts
        #expect(updated.count == 1)
        #expect(updated.first?.value.name == "updated")
    }

    @Test("Update of irrelevant attribute does not trigger service update")
    func updateOfIrrelevantAttributeDoesNotTriggerSyncServiceUpdate() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(name: "original")
        try await database.insert(workout)

        // relevantAttributes watches only \.name, but we change comment
        let mockService = MockSyncService(relevantAttributes: [\.name])
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        let workouts = try await database.fetchWorkouts()
        guard var modifiedWorkout = workouts.first else { throw "No workout found after insert." }
        modifiedWorkout.comment = "new comment"
        _ = try await database.update(modifiedWorkout)

        try await syncManager.performSync()

        let updated = await mockService.updatedWorkouts
        #expect(updated.isEmpty)
    }

    @Test("Delete triggers service delete")
    func deleteTriggersSyncServiceDelete() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        try await database.delete(workout)
        try await syncManager.performSync()

        let deletedIds = await mockService.deletedWorkoutIds
        #expect(deletedIds.contains(workout.id))
    }

    @Test("Workout from same sync service is not re-synced outbound")
    func workoutFromSameSyncServiceIsNotReSyncedOutbound() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .syncService(identifier: "mock"))
        try await database.insert(workout)

        let mockService = MockSyncService(identifier: "mock")
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        let inserted = await mockService.insertedWorkouts
        #expect(inserted.isEmpty)
    }

    @Test("Workout from different sync service is synced outbound")
    func workoutFromDifferentSyncServiceIsSyncedOutbound() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .syncService(identifier: "other-service"))
        try await database.insert(workout)

        let mockService = MockSyncService(identifier: "mock")
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        let inserted = await mockService.insertedWorkouts
        #expect(inserted.count == 1)
        #expect(inserted.first?.key == workout.id)
    }

    @Test("Successful insert persists synced mapping with external ID")
    func successfulInsertPersistsSyncedMappingWithExternalId() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        let workouts = try await database.fetchWorkouts()
        let mapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "mock" })
        #expect(mapping?.syncStatus == .synced)
        #expect(mapping?.externalId == "mock-external-id")
    }

    @Test("Failed insert persists failed mapping")
    func failedInsertPersistsFailedMapping() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockService = MockSyncService(insertError: NSError(domain: "test", code: 1))
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
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

        let mockService = MockSyncService(insertError: SyncError.serviceUnavailable)
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        let inserted = await mockService.insertedWorkouts
        // First workout should trigger the error, second should not be attempted
        #expect(inserted.count <= 1)
    }

    @Test("Conflict status prevents future automatic syncs")
    func conflictStatusPreventsFutureAutomaticSyncs() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(name: "original")
        try await database.insert(workout)

        let mockService = MockSyncService(insertError: SyncError.conflict)
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.performSync()

        // Verify conflict status is set
        var workouts = try await database.fetchWorkouts()
        var mapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "mock" })
        #expect(mapping?.syncStatus == .conflict)

        // Now update the workout
        guard var modifiedWorkout = workouts.first else { throw "No workout found" }
        modifiedWorkout.name = "updated"
        _ = try await database.update(modifiedWorkout)

        // Clear the mock's state
        await mockService.reset()
        
        // Perform another sync - the workout should NOT be synced because it has conflict status
        try await syncManager.performSync()

        let updated = await mockService.updatedWorkouts
        #expect(updated.isEmpty, "Workout with conflict status should not be automatically synced")
    }

    @Test("Failed status allows retry on next sync")
    func failedStatusAllowsRetryOnNextSync() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockService = MockSyncService(insertError: NSError(domain: "test", code: 1))
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
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
        let delegate: any SyncDelegate = database

        let returnedId = try await delegate.insert(workout)

        #expect(returnedId == workout.id)
        let workouts = try await database.fetchWorkouts()
        #expect(workouts.contains(where: { $0.id == workout.id }))
    }

    @Test("SyncDelegate update modifies existing workout")
    func syncDelegateUpdateModifiesExistingWorkout() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(name: "original")
        let delegate: any SyncDelegate = database
        _ = try await delegate.insert(workout)

        var modified = workout
        modified.name = "updated"
        _ = try await delegate.update(modified)

        let workouts = try await database.fetchWorkouts()
        #expect(workouts.first?.name == "updated")
    }

    @Test("SyncDelegate delete removes workout from database")
    func syncDelegateDeleteRemovesWorkoutFromDatabase() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        let delegate: any SyncDelegate = database
        _ = try await delegate.insert(workout)

        try await delegate.delete(workout)

        let workouts = try await database.fetchWorkouts()
        #expect(workouts.isEmpty)
    }

    // MARK: - Initial Sync

    @Test("initiallySync propagates existing workouts to service")
    func initiallySyncPropagatesExistingWorkoutsToService() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .native)
        try await database.insert(workout)

        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.initiallySync(mockService, from: .distantPast, upTo: .now)

        let inserted = await mockService.insertedWorkouts
        #expect(inserted.count == 1)
        #expect(inserted.first?.key == workout.id)
    }

    @Test("initiallySync skips workouts from same sync service")
    func initiallySyncSkipsWorkoutsFromSameSyncService() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .syncService(identifier: "mock"))
        try await database.insert(workout)

        let mockService = MockSyncService(identifier: "mock")
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        try await syncManager.initiallySync(mockService, from: .distantPast, upTo: .now)

        let inserted = await mockService.insertedWorkouts
        #expect(inserted.isEmpty)
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

        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        // Only sync workouts starting from 24h ago
        try await syncManager.initiallySync(mockService, from: now.addingTimeInterval(-24 * 3600), upTo: now)

        let inserted = await mockService.insertedWorkouts
        #expect(inserted.isEmpty)
    }

    // MARK: - User-Initiated Sync

    @Test("User-initiated sync waits for ongoing sync")
    func userInitiatedSyncWaitsForOngoingSync() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let mockService = MockSyncService()
        let syncManager = await SyncManager(database: database, syncServices: [mockService])
        
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
        let inserted = await mockService.insertedWorkouts
        #expect(inserted.count == 1)
    }

    // MARK: - Multiple Services

    @Test("One service failure does not affect other services")
    func oneServiceFailureDoesNotAffectOtherServices() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)

        let failingService = MockSyncService(identifier: "failing", insertError: SyncError.serviceUnavailable)
        let workingService = MockSyncService(identifier: "working")
        let syncManager = await SyncManager(database: database, syncServices: [failingService, workingService])
        
        try await syncManager.performSync()

        // Working service should have synced successfully
        let workingInserted = await workingService.insertedWorkouts
        #expect(workingInserted.count == 1)
        
        // Failing service should have failed
        let failingInserted = await failingService.insertedWorkouts
        #expect(failingInserted.count <= 1)
        
        // Check mappings
        let workouts = try await database.fetchWorkouts()
        let workingMapping = workouts.first?.serviceMappings.first(where: { $0.serviceIdentifier == "working" })
        #expect(workingMapping?.syncStatus == .synced)
    }

    @Test("Workout syncs to all enabled services except its source")
    func workoutSyncsToAllEnabledServicesExceptItsSource() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(source: .syncService(identifier: "service-a"))
        try await database.insert(workout)

        let serviceA = MockSyncService(identifier: "service-a")
        let serviceB = MockSyncService(identifier: "service-b")
        let serviceC = MockSyncService(identifier: "service-c")
        let syncManager = await SyncManager(database: database, syncServices: [serviceA, serviceB, serviceC])
        
        try await syncManager.performSync()

        // Service A (source) should not receive the workout
        let serviceAInserted = await serviceA.insertedWorkouts
        #expect(serviceAInserted.isEmpty)
        
        // Services B and C should receive it
        let serviceBInserted = await serviceB.insertedWorkouts
        #expect(serviceBInserted.count == 1)
        
        let serviceCInserted = await serviceC.insertedWorkouts
        #expect(serviceCInserted.count == 1)
    }
}
