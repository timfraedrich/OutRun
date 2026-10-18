//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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
@testable import OutRun
@testable import OutRunCore
import Testing
import Combine
import Perception
import AsyncAlgorithms

@Suite("Legacy Database Migration Tests")
class LegacyMigrationTests {
    
    @Test("Migrate From Legacy Database V1")
    func migrateFromLegacyV1() async throws {
        try await performLegacyMigration(
            legacyBackupName: "OutRunV1",
            expectedWorkoutsName: "ExpectationOutRunV1"
        ) { (database: LegacyDatabase<LegacyDataModelV1>, legacyWorkouts: [LegacyRawDataModelV1.Workout]) in
            try await database.insert(legacyWorkouts)
        }
    }
    
    @Test("Migrate From Legacy Database V2")
    func migrateFromLegacyV2() async throws {
        try await performLegacyMigration(
            legacyBackupName: "OutRunV2",
            expectedWorkoutsName: "ExpectationOutRunV2"
        ) { (database: LegacyDatabase<LegacyDataModelV2>, legacyWorkouts: [LegacyRawDataModelV2.Workout]) in
            try await database.insert(legacyWorkouts)
        }
    }
    
    @Test("Migrate From Legacy Database V3")
    func migrateFromLegacyV3() async throws {
        try await performLegacyMigration(
            legacyBackupName: "OutRunV3",
            expectedWorkoutsName: "ExpectationOutRunV3"
        ) { (database: LegacyDatabase<LegacyDataModelV3>, legacyWorkouts: [LegacyRawDataModelV3.Workout]) in
            try await database.insert(legacyWorkouts)
        }
    }
    
    // MARK: Helper Methods
    
    private func prepareLegacyDataManager<DataModel: LegacyDataModel>(legacyStorageFileName: String) async throws -> LegacyDatabase<DataModel> {
        let legacyStorageURL = LegacyDatabase<DataModel>.legacyStorageURL(for: legacyStorageFileName)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: legacyStorageURL.relativePath) {
            try fileManager.removeItem(atPath: legacyStorageURL.relativePath)
        }
        return try await LegacyDatabase<DataModel>(fileName: legacyStorageFileName)
    }
    
    private func migrateAndCheckResults(for legacyStorageFileName: String, and expectedResults: [RawWorkout]) async throws {
        let core = await OutRunCore(config: .init(isStoredInMemoryOnly: true, recordableDataTypes: [.location]))
        let statusSequence = await MainActor.run { Perceptions { core.status } }.buffer(policy: .unbounded)
        for await status in statusSequence where status != .initializing { break }
        #expect(await core.status == .needsSetup)
        guard let database = await core.database else { throw "Database was not initialized." }
        let (task, progressStream) = LegacyMigrationHelper.performLegacyMigration(for: legacyStorageFileName, core: core)
        guard let task else { throw "Migration task was not returned." }
        for try await _ in progressStream { }
        await task.value
        try checkMigratedData(actual: try await database.fetchWorkouts(), expected: expectedResults)
    }
    
    private func checkMigratedData(actual actualWorkouts: [RawWorkout], expected expectedWorkouts: [RawWorkout]) throws {
        let sortDescriptor = SortDescriptor<RawWorkout>(\.startDate)
        #expect(Set(actualWorkouts.map(\.id)) == Set(expectedWorkouts.map(\.id)))
        #expect(actualWorkouts.sorted(using: sortDescriptor) == expectedWorkouts.sorted(using: sortDescriptor))
    }
    
    private func performLegacyMigration<R: Codable, L: LegacyDataModel>(
        legacyBackupName: String,
        expectedWorkoutsName: String,
        insertImplementation: @escaping (LegacyDatabase<L>, [R]) async throws -> Void
    ) async throws {
        let legacyBackup: LegacyBackup<R> = try TestUtil.readORBUP(with: legacyBackupName)
        let legacyWorkouts: [R] = legacyBackup.workoutData
        let legacyStorageFileName = legacyBackupName + "Migration"
        let manager: LegacyDatabase<L> = try await prepareLegacyDataManager(legacyStorageFileName: legacyStorageFileName)
        try await insertImplementation(manager, legacyWorkouts)
        await manager.close()
        #expect(await manager.storageExistsOnDisk())
        let expectedWorkouts: [RawWorkout] = try TestUtil.readJSON(with: expectedWorkoutsName)
        try await migrateAndCheckResults(for: legacyStorageFileName, and: expectedWorkouts)
        #expect(!(await manager.storageExistsOnDisk()))
    }
}
