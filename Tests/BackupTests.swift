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
@testable import OutRun
@testable import OutRunCore
import Testing

@Suite("Backup Tests")
class BackupTests {
    
    @Test("Full Backup And Full Restore")
    func checkExampleData() async throws {
        let exampleWorkouts: [RawWorkout] = try TestUtil.readJSON(with: "ExpectationOutRunV3")
        let (core, backupService) = try await initializeAndSetUpCoreAndBackupService()
        try await core.insert(exampleWorkouts)
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let (backupTask, _) = backupService.backup(to: directory, using: .model)
        let backupURL = try await backupTask.value
        guard let user = await core.user else { throw "Core is not set up with user." }
        try await core.reset()
        try await core.setup(for: user)
        let (restoreTask, _) = backupService.restore(from: backupURL)
        _ = try await restoreTask.value
        let restoredWorkouts = try await core.fetchWorkouts()
        try fileManager.removeItem(at: backupURL)
        #expect(Set(exampleWorkouts.map(\.id)) == Set(restoredWorkouts.map(\.id)))
    }
    
    @Test("V1 Legacy Backup Restore")
    func restoreV1LegacyBackup() async throws {
        try await restoreLegacyBackup(with: "OutRunV1", andCompareWithWorkoutsWith: "ExpectationOutRunV1")
    }
    
    @Test("V2 Legacy Backup Restore")
    func restoreV2LegacyBackup() async throws {
        try await restoreLegacyBackup(with: "OutRunV2", andCompareWithWorkoutsWith: "ExpectationOutRunV2")
    }
    
    @Test("V3 Legacy Backup Restore")
    func restoreV3LegacyBackup() async throws {
        try await restoreLegacyBackup(with: "OutRunV3", andCompareWithWorkoutsWith: "ExpectationOutRunV3")
    }
    
    // MARK: Helper
    
    private func initializeAndSetUpCoreAndBackupService() async throws -> (OutRunCore, BackupService) {
        let user = RawUser(name: "User", creationDate: .distantPast)
        let core = await OutRunCore(config: .init(isStoredInMemoryOnly: true))
        await core.wait(for: .needsSetup)
        try await core.setup(for: user)
        let backupService = BackupService(core: core)
        return (core, backupService)
    }
    
    private func restoreLegacyBackup(with legacyBackupName: String, andCompareWithWorkoutsWith expectedWorkoutsName: String) async throws {
        let legacyBackupURL = try TestUtil.orbupFileURL(forResource: legacyBackupName)
        let expectedWorkoutsURL = try TestUtil.jsonFileURL(forResource: expectedWorkoutsName)
        let expectedWorkouts: [RawWorkout] = try TestUtil.readJSON(at: expectedWorkoutsURL)
        let (core, backupService) = try await initializeAndSetUpCoreAndBackupService()
        let (restoreTask, _) = backupService.restore(from: legacyBackupURL)
        _ = try await restoreTask.value
        let restoredWorkouts = try await core.fetchWorkouts()
        #expect(Set(expectedWorkouts.map(\.id)) == Set(restoredWorkouts.map(\.id)))
    }
}
