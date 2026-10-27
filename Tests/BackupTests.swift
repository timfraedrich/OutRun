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
import ZIPFoundation

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
    
    @Test("Restore Zip With Mixed File Types")
    func restoreZipWithMixedFileTypes() async throws {
        let legacyBackupURL = try TestUtil.orbupFileURL(forResource: "OutRunV3")
        let expectedLegacyWorkouts: [RawWorkout] = try TestUtil.readJSON(with: "ExpectationOutRunV3")
        guard let gpxWorkout = expectedLegacyWorkouts.first else { throw "No example workout available." }
        let (core, backupService) = try await initializeAndSetUpCoreAndBackupService()
        try await core.insert([gpxWorkout])
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory.appending(component: UUID().uuidString)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }
        _ = try await backupService.backup([gpxWorkout.id], to: directory, using: .gpx).task.value
        let gpxURL = directory.appending(component: gpxWorkout.id.uuidString + ".gpx")
        guard let user = await core.user else { throw "Core is not set up with user." }
        try await core.reset()
        try await core.setup(for: user)

        let archiveURL = directory.appending(component: "mixed.zip")
        let archive = try Archive(url: archiveURL, accessMode: .create)
        try archive.addEntry(with: "legacy.orbup", fileURL: legacyBackupURL)
        try archive.addEntry(with: "workout.gpx", fileURL: gpxURL)
        let notesURL = directory.appending(component: "notes.txt")
        try Data("notes".utf8).write(to: notesURL)
        try archive.addEntry(with: "notes.txt", fileURL: notesURL)
        #expect(try backupService.checkRestoreURL(archiveURL) == [.gpxWillAlwaysAddNewWorkouts, .notAllFilesAreImportable])
        let result = try await backupService.restore(from: archiveURL).task.value

        let restoredWorkouts = try await core.fetchWorkouts()
        #expect(result.failed == 0)
        #expect(result.upserted == expectedLegacyWorkouts.count + 1)
        #expect(restoredWorkouts.count == expectedLegacyWorkouts.count + 1)
        #expect(Set(expectedLegacyWorkouts.map(\.id)).isSubset(of: restoredWorkouts.map(\.id)))
    }

    @Test("Backup Warnings")
    func backupWarnings() async throws {
        let (_, backupService) = try await initializeAndSetUpCoreAndBackupService()
        #expect(backupService.checkBackup(using: .model).isEmpty)
        #expect(backupService.checkBackup([UUID()], using: .gpx).isEmpty)
        #expect(backupService.checkBackup([UUID(), UUID()], using: .gpx) == [.individualFilesWillBeWritten])
        #expect(backupService.checkBackup(using: .gpx) == [.individualFilesWillBeWritten])
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
