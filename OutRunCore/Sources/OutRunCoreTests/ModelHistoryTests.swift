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
import SwiftData
import Testing

/// On iOS 18 `fetchHistory` crashes the process once a transaction updates an enum or other `Codable` type stored directly on a model, so
/// the update tests only detect regressions when run on an iOS 18 destination. The schema test applies to all destinations.
@Suite("Model History Tests", .serialized)
@MainActor
struct ModelHistoryTests {
    
    @Test("Models Do Not Store Composite Attributes")
    func modelsDoNotStoreCompositeAttributes() {
        let schema = Schema(versionedSchema: ModelSchema.self)
        let compositeAttributes = schema.entities.flatMap { entity in
            entity.attributes.filter { $0 is Schema.CompositeAttribute }.map { "\(entity.name).\($0.name)" }
        }
        #expect(compositeAttributes.isEmpty)
    }
    
    @Test("Migration Keeps Sex And Sync Mode")
    func migrationKeepsValues() throws {
        let directory = URL.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "default.store")
        let startDate = Date(timeIntervalSinceReferenceDate: 1_000)
        do {
            let schema = Schema(versionedSchema: ModelSchemaV2_0_0.self)
            let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            let context = ModelContext(try ModelContainer(for: schema, configurations: configuration))
            let preferences: RawPreferences = ["key": Data([1])]
            context.insert(ModelSchemaV2_0_0.User(name: "Test", sex: .female, preferences: preferences, creationDate: .now))
            context.insert(ModelSchemaV2_0_0.SyncServiceState(id: "from", lastSyncMode: .enabledFrom(date: startDate), preferences: preferences))
            context.insert(ModelSchemaV2_0_0.SyncServiceState(id: "disabled", lastSyncMode: .disabled, preferences: [:]))
            try context.save()
        }
        let schema = Schema(versionedSchema: ModelSchema.self)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, migrationPlan: ModelMigrationPlan.self, configurations: configuration)
        let context = ModelContext(container)
        let user = try #require(try context.fetch(FetchDescriptor<User>()).first)
        #expect(user.sex == .female)
        #expect(user.preferences == ["key": Data([1])])
        let states = try context.fetch(FetchDescriptor<SyncServiceState>())
        let state = try #require(states.first { $0.id == "from" })
        #expect(state.lastSyncMode == .enabledFrom(date: startDate))
        #expect(state.preferences == ["key": Data([1])])
        #expect(states.first { $0.id == "disabled" }?.lastSyncMode == .disabled)
        user.sex = .male
        state.lastSyncMode = .enabled
        try context.save()
        _ = try ModelContext(container).fetchHistory(HistoryDescriptor<DefaultHistoryTransaction>()).map(\.changes)
    }
    
    @Test("User Updates And Deletion Keep History Readable")
    func user() throws {
        try expectReadableHistory { context in
            let user = User(id: UUID(), name: "Test", sex: .male, creationDate: .now)
            context.insert(user)
            try context.save()
            user.name = "Updated"
            user.birthday = try .init(dayIdentifier: "2000-01-01")
            user.weight = 70
            user.sex = .female
            user.preferences = ["key": Data([1])]
            user.lastEditDate = .now
            try context.save()
            user.sex = nil
            try context.save()
            context.delete(user)
            try context.save()
        }
    }
    
    @Test("Workout Updates And Deletion Keep History Readable")
    func workout() throws {
        try expectReadableHistory { context in
            let workout = makeWorkout()
            context.insert(workout)
            try context.save()
            workout.type = .cycling
            workout.source = .syncService(identifier: "service")
            workout.distance = 2
            workout.endDate = .now
            workout.energy = 1
            workout.repetitions = 1
            workout.isRace = true
            workout.name = "Name"
            workout.comment = "Comment"
            workout.lastEditDate = .now
            try context.save()
            workout.type = .unknown(rawValue: "type")
            workout.source = .unknown(rawValue: "source")
            try context.save()
            context.delete(workout)
            try context.save()
        }
    }
    
    @Test("Route Sample Updates And Deletion Keep History Readable")
    func routeSample() throws {
        try expectReadableHistory { context in
            let sample = WorkoutRouteDataSample(
                timestamp: .now,
                latitude: 1,
                longitude: 1,
                altitude: 1,
                horizontalAccuracy: 1,
                verticalAccuracy: 1,
                speed: 1,
                workout: makeWorkout()
            )
            context.insert(sample)
            try context.save()
            sample.timestamp = .now
            sample.latitude = 2
            sample.longitude = 2
            sample.altitude = 2
            sample.horizontalAccuracy = 2
            sample.verticalAccuracy = 2
            sample.speed = 2
            try context.save()
            context.delete(sample)
            try context.save()
        }
    }
    
    @Test("Heart Rate Sample Updates And Deletion Keep History Readable")
    func heartRateSample() throws {
        try expectReadableHistory { context in
            let sample = WorkoutHeartRateDataSample(heartRate: 1, timestamp: .now, workout: makeWorkout())
            context.insert(sample)
            try context.save()
            sample.heartRate = 2
            sample.timestamp = .now
            try context.save()
            context.delete(sample)
            try context.save()
        }
    }
    
    @Test("Pause Updates And Deletion Keep History Readable")
    func pause() throws {
        try expectReadableHistory { context in
            let pause = WorkoutPause(startDate: .now, endDate: .now, userInitiated: true, workout: makeWorkout())
            context.insert(pause)
            try context.save()
            pause.startDate = .now
            pause.endDate = .now
            pause.userInitiated = false
            try context.save()
            context.delete(pause)
            try context.save()
        }
    }
    
    @Test("Event Updates And Deletion Keep History Readable")
    func event() throws {
        try expectReadableHistory { context in
            let event = WorkoutEvent(type: .unknown(rawValue: 1), timestamp: .now, workout: makeWorkout())
            context.insert(event)
            try context.save()
            event.type = .unknown(rawValue: 2)
            event.timestamp = .now
            try context.save()
            context.delete(event)
            try context.save()
        }
    }
    
    @Test("Service Mapping Updates And Deletion Keep History Readable")
    func serviceMapping() throws {
        try expectReadableHistory { context in
            let mapping = SyncServiceMapping(
                serviceIdentifier: "service",
                externalId: nil,
                externalUrl: nil,
                lastEditDateSynced: nil,
                syncStatus: .unknown(rawValue: "first"),
                workout: makeWorkout()
            )
            context.insert(mapping)
            try context.save()
            mapping.externalId = "id"
            mapping.externalUrl = "url"
            mapping.lastEditDateSynced = .now
            mapping.syncStatus = .unknown(rawValue: "second")
            try context.save()
            context.delete(mapping)
            try context.save()
        }
    }
    
    @Test("Service State Updates And Deletion Keep History Readable")
    func serviceState() throws {
        try expectReadableHistory { context in
            let state = SyncServiceState(id: "service")
            context.insert(state)
            try context.save()
            state.lastSyncDate = .now
            state.lastSyncMode = .enabled
            state.preferences = ["key": Data([1])]
            try context.save()
            state.lastSyncMode = .enabledFrom(date: .now)
            try context.save()
            #expect(state.lastSyncMode.isEnabled)
            state.lastSyncMode = .disabled
            try context.save()
            #expect(state.lastSyncMode == .disabled)
            context.delete(state)
            try context.save()
        }
    }
    
    // MARK: - Helpers
    
    private func makeWorkout() -> Workout {
        Workout(
            type: .running,
            distance: 1,
            startDate: .now,
            endDate: nil,
            energy: nil,
            repetitions: nil,
            isRace: false,
            name: nil,
            creationDate: .now,
            source: .native
        )
    }
    
    private func expectReadableHistory(after changes: (ModelContext) throws -> Void) throws {
        let container = try Database.modelContainer(name: nil, isStoredInMemoryOnly: true)
        try changes(ModelContext(container))
        var updateCount = 0
        var deleteCount = 0
        for transaction in try ModelContext(container).fetchHistory(HistoryDescriptor<DefaultHistoryTransaction>()) {
            for change in transaction.changes {
                switch change {
                case .update(let update):
                    readAttributes(of: update)
                    updateCount += 1
                case .delete(let delete):
                    readTombstone(of: delete)
                    deleteCount += 1
                default:
                    break
                }
            }
        }
        #expect(updateCount > 0)
        #expect(deleteCount > 0)
    }
    
    private func readAttributes<Update: HistoryUpdate>(of update: Update) {
        _ = update.updatedAttributes
    }
    
    private func readTombstone<Delete: HistoryDelete>(of delete: Delete) {
        _ = delete.tombstone
    }
}
