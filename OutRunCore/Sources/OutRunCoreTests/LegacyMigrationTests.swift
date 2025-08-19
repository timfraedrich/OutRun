import Foundation
@testable import OutRunCore
import Testing

@Suite("Legacy Database Migration Tests")
struct LegacyMigrationTests {
    
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
        let database = try await Database(isStoredInMemoryOnly: true, legacyStorageFileName: legacyStorageFileName)
        #expect(!(await manager.storageExistsOnDisk()))
        try checkMigratedData(actual: try database.fetchWorkouts(), expected: try readV1ExpectedResults())
    }
    
    @Test("Migrate From Legacy Database V2")
    func migrateFromLegacyV2() async throws {
        let exampleData = try readV2ExampleData()
        let legacyStorageFileName = "V2Migration"
        let manager: LegacyDatabase<LegacyDataModelV2> = try await prepareLegacyDataManager(legacyStorageFileName: legacyStorageFileName)
        try await manager.insert(exampleData)
        await manager.close()
        #expect(await manager.storageExistsOnDisk())
        let database = try await Database(isStoredInMemoryOnly: true, legacyStorageFileName: legacyStorageFileName)
        #expect(!(await manager.storageExistsOnDisk()))
        try checkMigratedData(actual: try database.fetchWorkouts(), expected: try readV2ExpectedResults())
    }
    
    @Test("Migrate From Legacy Database V3")
    func migrateFromLegacyV3() async throws {
        let exampleData = try readV3ExampleData()
        let legacyStorageFileName = "V3Migration"
        let manager: LegacyDatabase<LegacyDataModelV3> = try await prepareLegacyDataManager(legacyStorageFileName: legacyStorageFileName)
        try await manager.insert(exampleData)
        await manager.close()
        #expect(await manager.storageExistsOnDisk())
        let database = try await Database(isStoredInMemoryOnly: true, legacyStorageFileName: legacyStorageFileName)
        #expect(!(await manager.storageExistsOnDisk()))
        try checkMigratedData(actual: try database.fetchWorkouts(), expected: try readV3ExpectedResults())
    }
    
    // MARK: Helper Methods
    
    private func readExampleData<C: Codable>(filename: String) throws -> [C] {
        guard let url = Bundle.module.url(forResource: filename, withExtension: "json") else {
            throw "Invalid URL for example workouts json file."
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(LegacyBackup<C>.self, from: data).workoutData
    }
    
    private func readV1ExampleData() throws -> [RawDataModelV1.Workout] {
        try readExampleData(filename: "OutRunV1")
    }
    
    private func readV2ExampleData() throws -> [RawDataModelV2.Workout] {
        try readExampleData(filename: "OutRunV2")
    }
    
    private func readV3ExampleData() throws -> [RawDataModelV3.Workout] {
        try readExampleData(filename: "OutRunV3")
    }
    
    private func readExpectedResults(filename: String) throws -> [RawWorkout] {
        guard let url = Bundle.module.url(forResource: filename, withExtension: "json") else {
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
    
    private func prepareLegacyDataManager<DataModel: CoreStoreDataModel>(legacyStorageFileName: String) async throws -> LegacyDatabase<DataModel> {
        let legacyStorageURL = LegacyDatabase<DataModel>.legacyStorageURL(for: legacyStorageFileName)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: legacyStorageURL.relativePath) {
            try fileManager.removeItem(atPath: legacyStorageURL.relativePath)
        }
        return try await LegacyDatabase<DataModel>(fileName: legacyStorageFileName)
    }
    
    private func checkMigratedData(actual actualWorkouts: [Workout], expected expectedWorkouts: [RawWorkout]) throws {
        let sortDescriptor = SortDescriptor<RawWorkout>(\.startDate)
        let rawWorkouts = actualWorkouts.map(RawWorkout.init)
        #expect(Set(rawWorkouts.map(\.id)) == Set(expectedWorkouts.map(\.id)))
        #expect(rawWorkouts.sorted(using: sortDescriptor) == expectedWorkouts.sorted(using: sortDescriptor))
    }
}
