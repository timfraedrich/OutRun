import Foundation
@testable import OutRun
@testable import OutRunCore
import Testing

@Suite("Backup Tests")
class BackupTests {
    
    @Test("Full Backup And Full Restore")
    func checkExampleData() async throws {
        let exampleWorkouts: [RawWorkout] = try TestUtil.readJSON(filename: "ExpectationOutRunV3")
        let user = RawUser(name: "User", creationDate: .distantPast)
        let core = await OutRunCore(config: .init(isStoredInMemoryOnly: true))
        await core.wait(for: .needsSetup)
        try await core.setup(for: user)
        try await core.insert(exampleWorkouts)
        let backupService = BackupService(core: core)
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let (backupTask, _) = backupService.backup(to: directory)
        let backupURL = try await backupTask.value
        try await core.reset()
        try await core.setup(for: user)
        let (restoreTask, _) = backupService.restoreBackup(from: backupURL)
        _ = try await restoreTask.value
        let restoredWorkouts = try await core.fetchWorkouts()
        try fileManager.removeItem(at: backupURL)
        #expect(Set(exampleWorkouts.map(\.id)) == Set(restoredWorkouts.map(\.id)))
    }
}
