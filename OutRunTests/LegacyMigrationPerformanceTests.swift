import Foundation
@testable import OutRun
@testable import OutRunCore
import Testing
import Combine
import Perception
import AsyncAlgorithms
import OSLog

@Suite("Legacy Migration Performance Tests", .serialized)
class LegacyMigrationPerformanceTests {
    
    private let logger = Logger(category: "LegacyMigrationPerformanceTests")
    
    // @Test("Baseline") // 222997 ms
    // func baselineMigration() async throws {
    //     try await performLegacyMigration("Baseline", migrationAction: LegacyMigrationHelper.performLegacyMigration)
    // }
    // 
    // @Test("New") // 119159 ms (1.9x faster)
    // func newMigration() async throws {
    //     try await performLegacyMigration("New", migrationAction: NewLegacyMigrationHelper.performLegacyMigration)
    // }
    //
    // @Test("Gold") // 38187 ms (5.8x faster)
    // func goldMigration() async throws {
    //     try await performLegacyMigration("Gold", migrationAction: GoldLegacyMigrationHelper.performLegacyMigration)
    // }
    //
    // @Test("Diamond") // 36401 ms (6.1x faster)
    // func diamondMigration() async throws {
    //     try await performLegacyMigration("Diamond", migrationAction: DiamondLegacyMigrationHelper.performLegacyMigration)
    // }
    
    // MARK: Helper Methods
    
    private func performLegacyMigration(
        _ name: String,
        legacyBackupName: String = "20220227-232230", // "OutRunV3", //
        migrationAction: (String, OutRunCore) -> (Task<Void, Never>?, AsyncThrowingStream<Float, Error>)
    ) async throws {
        
        let core = await OutRunCore(config: .init(isStoredInMemoryOnly: true, recordableDataTypes: [.location]))
        let statusSequence = await MainActor.run { Perceptions { core.status } }.buffer(policy: .unbounded)
        for await status in statusSequence where status != .initializing { break }
        #expect(await core.status == .needsSetup)
        guard let database = await core.database else { throw "Database was not initialized." }
        
        let legacyBackup: LegacyBackup<LegacyRawDataModelV3.Workout> = try TestUtil.readJSON(with: legacyBackupName)
        let legacyWorkouts: [LegacyRawDataModelV3.Workout] = legacyBackup.workoutData
        let legacyStorageFileName = name
        let legacyStorageURL = LegacyDatabase<LegacyDataModelV3>.legacyStorageURL(for: legacyStorageFileName)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: legacyStorageURL.relativePath) {
            try fileManager.removeItem(atPath: legacyStorageURL.relativePath)
        }
        let manager = try await LegacyDatabase<LegacyDataModelV3>(fileName: legacyStorageFileName)
        try await manager.insert(legacyWorkouts)
        await manager.close()
        #expect(await manager.storageExistsOnDisk())
        
        let migrationStart = Date.now
        
        let (task, progressStream) = migrationAction(legacyStorageFileName, core)
        guard let task else { throw "Migration task was not returned." }
        var lastProgress: Float = 0
        for try await progress in progressStream where progress > lastProgress {
            logger.info("Running \(name) Migration... \(progress * 100) %")
            lastProgress = progress
        }
        await task.value
        
        let migrationEnd = Date.now
        
        #expect(!(await manager.storageExistsOnDisk()))
        let actualWorkouts: [RawWorkout] = try await database.fetchWorkouts()
        #expect(Set(actualWorkouts.map(\.id)) == Set(legacyWorkouts.compactMap(\.uuid)))
        
        let duration = migrationStart.distance(to: migrationEnd)
        let formattedDuration = String(Int(duration * 1000)) + " ms"
        logger.info("Ran \(name) Migration in \(formattedDuration)")
    }
}
