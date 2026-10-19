//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation
@testable import OutRunCore
import Testing

@Suite("Manual Sync Tests")
struct ManualSyncTests {

    // MARK: - Helpers

    private func makeWorkout(
        name: String? = nil,
        source: WorkoutSource = .native,
        isFinished: Bool = true,
        serviceMappings: [RawSyncServiceMapping] = []
    ) -> RawWorkout {
        let now = Date.now
        return RawWorkout(
            id: .init(),
            type: .running,
            distance: 1000,
            startDate: now.addingTimeInterval(-3600),
            endDate: isFinished ? now : nil,
            energy: nil,
            repetitions: nil,
            isRace: false,
            name: name,
            comment: nil,
            creationDate: now,
            lastEditDate: now,
            source: source,
            serviceMappings: serviceMappings
        )
    }

    private func makeSyncManager(with database: Database, service: MockSyncService) async -> SyncManager {
        let delegate = await MockSyncDelegate(database: database)
        return await SyncManager(database: database, syncDelegate: delegate, syncServices: [service])
    }

    private func mapping(ofWorkoutWith id: UUID, in database: Database) async throws -> RawSyncServiceMapping? {
        try await database.fetchWorkout(for: id).serviceMappings.first(where: { $0.serviceIdentifier == "mock" })
    }

    private func importedWorkout(name: String?, lastEditDate: Date) -> RawWorkout {
        var workout = makeWorkout(
            name: name,
            source: .syncService(identifier: "mock"),
            serviceMappings: [.init(serviceIdentifier: "mock", externalId: "external", syncStatus: .synced)]
        )
        workout.lastEditDate = lastEditDate
        return workout
    }

    // MARK: - Options

    @Test("Options offer initial sync, resync and import depending on the workout")
    func optionsDependOnWorkout() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let notSynced = makeWorkout()
        let synced = makeWorkout(serviceMappings: [.init(serviceIdentifier: "mock", externalId: "a", syncStatus: .synced)])
        let pending = makeWorkout(serviceMappings: [.init(serviceIdentifier: "mock", syncStatus: .pending)])
        let unfinished = makeWorkout(isFinished: false)
        let imported = importedWorkout(name: nil, lastEditDate: .now)
        let fromOtherService = makeWorkout(source: .syncService(identifier: "other"))
        try await database.insert([notSynced, synced, pending, unfinished, imported, fromOtherService])
        let syncManager = await makeSyncManager(with: database, service: MockSyncService())

        #expect(try await syncManager.syncOptions(forWorkoutWith: notSynced.id) == [.init(serviceIdentifier: "mock", action: .initialOutwardSync)])
        #expect(try await syncManager.syncOptions(forWorkoutWith: pending.id) == [.init(serviceIdentifier: "mock", action: .initialOutwardSync)])
        #expect(try await syncManager.syncOptions(forWorkoutWith: synced.id) == [.init(serviceIdentifier: "mock", action: .outwardResync)])
        #expect(try await syncManager.syncOptions(forWorkoutWith: imported.id) == [.init(serviceIdentifier: "mock", action: .inwardResync)])
        #expect(try await syncManager.syncOptions(forWorkoutWith: unfinished.id).isEmpty)
        #expect(try await syncManager.syncOptions(forWorkoutWith: fromOtherService.id).isEmpty)
    }

    @Test("Options offer outward sync to services with disabled automatic sync")
    func optionsIncludeDisabledServices() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)
        let syncManager = await makeSyncManager(with: database, service: MockSyncService(mode: .disabled))
        #expect(try await syncManager.syncOptions(forWorkoutWith: workout.id) == [.init(serviceIdentifier: "mock", action: .initialOutwardSync)])
    }

    @Test("Options offer outward sync for workouts before the start date of the service")
    func optionsIgnoreServiceStartDate() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)
        let service = MockSyncService(mode: .enabledFrom(date: .now.addingTimeInterval(3600)))
        let syncManager = await makeSyncManager(with: database, service: service)
        #expect(try await syncManager.syncOptions(forWorkoutWith: workout.id) == [.init(serviceIdentifier: "mock", action: .initialOutwardSync)])
    }

    // MARK: - Outward

    @Test("Initial outward sync upserts the workout and marks it as synced")
    func initialOutwardSync() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)
        let service = MockSyncService()
        let syncManager = await makeSyncManager(with: database, service: service)

        try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: false)

        #expect(await service.upsertedWorkouts[workout.id] != nil)
        let mapping = try await mapping(ofWorkoutWith: workout.id, in: database)
        #expect(mapping?.syncStatus == .synced)
        #expect(mapping?.externalId == "mock-external-id")
    }

    @Test("Outward resync resolves conflicted and failed workouts", arguments: [WorkoutSyncStatus.conflict, .failed])
    func outwardResyncResolvesStatus(status: WorkoutSyncStatus) async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(serviceMappings: [.init(serviceIdentifier: "mock", syncStatus: status)])
        try await database.insert(workout)
        let syncManager = await makeSyncManager(with: database, service: MockSyncService())

        try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: false)

        #expect(try await mapping(ofWorkoutWith: workout.id, in: database)?.syncStatus == .synced)
    }

    @Test("Outward resync over a newer version on the service requires replacing it")
    func outwardResyncOverNewerVersion() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout(serviceMappings: [.init(serviceIdentifier: "mock", externalId: "a", syncStatus: .synced)])
        try await database.insert(workout)
        let service = MockSyncService(hasNewerVersion: true)
        let syncManager = await makeSyncManager(with: database, service: service)

        await #expect(throws: SyncError.conflict) {
            try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: false)
        }
        #expect(try await mapping(ofWorkoutWith: workout.id, in: database)?.syncStatus == .conflict)
        #expect(await service.lastReplacingNewerVersion == false)

        try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: true)
        #expect(try await mapping(ofWorkoutWith: workout.id, in: database)?.syncStatus == .synced)
        #expect(await service.lastReplacingNewerVersion == true)
    }

    @Test("Failing outward resync marks the workout as failed and rethrows")
    func failingOutwardResync() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = makeWorkout()
        try await database.insert(workout)
        let syncManager = await makeSyncManager(with: database, service: MockSyncService(upsertError: SyncError.networkError))

        await #expect(throws: SyncError.networkError) {
            try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: false)
        }
        #expect(try await mapping(ofWorkoutWith: workout.id, in: database)?.syncStatus == .failed)
    }

    @Test("Outward resync is refused for unfinished workouts and workouts of other services")
    func outwardResyncRefusals() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let unfinished = makeWorkout(isFinished: false)
        let fromOtherService = makeWorkout(source: .syncService(identifier: "other"))
        try await database.insert([unfinished, fromOtherService])
        let service = MockSyncService()
        let syncManager = await makeSyncManager(with: database, service: service)

        await #expect(throws: SyncError.workoutNotFinished) {
            try await syncManager.resync(workoutWith: unfinished.id, withServiceWith: "mock", replacingNewerVersion: false)
        }
        await #expect(throws: SyncError.workoutNotSyncable) {
            try await syncManager.resync(workoutWith: fromOtherService.id, withServiceWith: "mock", replacingNewerVersion: false)
        }
        #expect(await service.upsertedWorkouts.isEmpty)
    }

    // MARK: - Inward

    @Test("Inward resync replaces an unchanged workout with the version from the service")
    func inwardResyncReplacesUnchangedWorkout() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let lastEditDate = Date.now
        let workout = importedWorkout(name: "original", lastEditDate: lastEditDate)
        try await database.insert(workout)
        // The service assigns a new core identifier whenever it converts a workout.
        let serviceWorkout = importedWorkout(name: "from service", lastEditDate: lastEditDate)
        let service = MockSyncService(serviceWorkouts: ["external": serviceWorkout])
        let syncManager = await makeSyncManager(with: database, service: service)

        try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: false)

        let workouts = try await database.fetchWorkouts()
        #expect(workouts.count == 1)
        #expect(workouts.first?.id == workout.id)
        #expect(workouts.first?.name == "from service")
    }

    @Test("Inward resync over local changes requires replacing them")
    func inwardResyncOverLocalChanges() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let serviceWorkout = importedWorkout(name: "from service", lastEditDate: .now.addingTimeInterval(-3600))
        let workout = importedWorkout(name: "edited locally", lastEditDate: .now)
        try await database.insert(workout)
        let service = MockSyncService(serviceWorkouts: ["external": serviceWorkout])
        let syncManager = await makeSyncManager(with: database, service: service)

        await #expect(throws: SyncError.conflict) {
            try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: false)
        }
        #expect(try await database.fetchWorkout(for: workout.id).name == "edited locally")

        try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: true)
        #expect(try await database.fetchWorkout(for: workout.id).name == "from service")
    }

    @Test("Inward resync of a workout missing on the service throws")
    func inwardResyncOfMissingWorkout() async throws {
        let database = try await Database(isStoredInMemoryOnly: true)
        let workout = importedWorkout(name: nil, lastEditDate: .now)
        try await database.insert(workout)
        let syncManager = await makeSyncManager(with: database, service: MockSyncService())

        await #expect(throws: SyncError.workoutNotFoundOnService) {
            try await syncManager.resync(workoutWith: workout.id, withServiceWith: "mock", replacingNewerVersion: false)
        }
        #expect(try await database.fetchWorkouts().count == 1)
    }
}
