import Foundation
@testable import OutRun
@testable import OutRunCore
import Testing
import Combine
import Perception
import AsyncAlgorithms

@Suite("Legacy Database Migration Tests")
class LegacyMigrationTests {
    
    @Test("Check Example Data")
    func checkExampleData() throws {
        let v1ExampleData = try readV1ExampleData()
        #expect(v1ExampleData.count == 3)
        let v2ExampleData = try readV2ExampleData()
        #expect(v2ExampleData.count == 3)
        let v3ExampleData = try readV3ExampleData()
        #expect(v3ExampleData.count == 3)
    }
    
    @Test("Check Expected Data")
    func checkExpectedData() throws {
        let v1ExpectedResults = try readV1ExpectedResults()
        #expect(v1ExpectedResults.count == 3)
        let v2ExpectedResults = try readV2ExpectedResults()
        #expect(v2ExpectedResults.count == 3)
        let v3ExpectedResults = try readV3ExpectedResults()
        #expect(v3ExpectedResults.count == 3)
    }
    
    @Test("Migrate From Legacy Database V1")
    func migrateFromLegacyV1() async throws {
        let exampleData = try readV1ExampleData()
        let legacyStorageFileName = "V1Migration"
        let manager: LegacyDatabase<LegacyDataModelV1> = try await prepareLegacyDataManager(legacyStorageFileName: legacyStorageFileName)
        try await manager.insert(exampleData)
        await manager.close()
        #expect(await manager.storageExistsOnDisk())
        try await migrateAndCheckResults(for: legacyStorageFileName, and: try readV1ExpectedResults())
        #expect(!(await manager.storageExistsOnDisk()))
    }
    
    @Test("Migrate From Legacy Database V2")
    func migrateFromLegacyV2() async throws {
        let exampleData = try readV2ExampleData()
        let legacyStorageFileName = "V2Migration"
        let manager: LegacyDatabase<LegacyDataModelV2> = try await prepareLegacyDataManager(legacyStorageFileName: legacyStorageFileName)
        try await manager.insert(exampleData)
        await manager.close()
        #expect(await manager.storageExistsOnDisk())
        try await migrateAndCheckResults(for: legacyStorageFileName, and: try readV2ExpectedResults())
        #expect(!(await manager.storageExistsOnDisk()))
    }
    
    @Test("Migrate From Legacy Database V3")
    func migrateFromLegacyV3() async throws {
        let exampleData = try readV3ExampleData()
        let legacyStorageFileName = "V3Migration"
        let manager: LegacyDatabase<LegacyDataModelV3> = try await prepareLegacyDataManager(legacyStorageFileName: legacyStorageFileName)
        try await manager.insert(exampleData)
        await manager.close()
        #expect(await manager.storageExistsOnDisk())
        try await migrateAndCheckResults(for: legacyStorageFileName, and: try readV3ExpectedResults())
        #expect(!(await manager.storageExistsOnDisk()))
    }
    
    // MARK: Helper Methods
    
    private func readExampleData<C: Codable>(filename: String) throws -> [C] {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: filename, withExtension: "json") else {
            throw "Invalid URL for example workouts json file."
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(LegacyBackup<C>.self, from: data).workoutData
    }
    
    private func readV1ExampleData() throws -> [LegacyRawDataModelV1.Workout] {
        try readExampleData(filename: "OutRunV1")
    }
    
    private func readV2ExampleData() throws -> [LegacyRawDataModelV2.Workout] {
        try readExampleData(filename: "OutRunV2")
    }
    
    private func readV3ExampleData() throws -> [LegacyRawDataModelV3.Workout] {
        try readExampleData(filename: "OutRunV3")
    }
    
    private func readExpectedResults(filename: String) throws -> [RawWorkout] {
        let testBundle = Bundle(for: type(of: self))
        guard let url = testBundle.url(forResource: filename, withExtension: "json") else {
            throw "Invalid URL for expected results json file."
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([RawWorkout].self, from: data)
    }
    
    private func readV1ExpectedResults() throws -> [RawWorkout] {
        try readExpectedResults(filename: "ExpectationOutRunV1")
    }
    
    private func readV2ExpectedResults() throws -> [RawWorkout] {
        try readExpectedResults(filename: "ExpectationOutRunV2")
    }
    
    private func readV3ExpectedResults() throws -> [RawWorkout] {
        try readExpectedResults(filename: "ExpectationOutRunV3")
    }
    
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
}
