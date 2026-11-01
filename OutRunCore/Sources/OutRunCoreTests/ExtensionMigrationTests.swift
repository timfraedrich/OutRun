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

import CoreData
import Foundation
@testable import OutRunCore
import SwiftData
import Testing

@Suite("Extension Migration Tests", .serialized)
@MainActor
struct ExtensionMigrationTests {

    private let name = UUID().uuidString

    private var url: URL {
        ModelConfiguration(name, groupContainer: .none, cloudKitDatabase: .none).url
    }

    @Test("Outdated Store Is Left Untouched")
    func outdatedStore() throws {
        defer { removeStore() }
        try createOutdatedStore()
        #expect(throws: OutRunCoreError.self) {
            try Database.modelContainer(name: name, groupContainer: .none, allowsMigration: false)
        }
        #expect(try storeVersions() == ["outdated"])
    }

    @Test("Store Of The Current Schema Opens Without Migration")
    func currentStore() throws {
        defer { removeStore() }
        do {
            let context = ModelContext(try Database.modelContainer(name: name, groupContainer: .none))
            context.insert(User(name: "Test", preferences: [:], creationDate: .now))
            try context.save()
        }
        let container = try Database.modelContainer(name: name, groupContainer: .none, allowsMigration: false)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<User>()) == 1)
    }

    @Test("Missing Store Gets Created Without Migration")
    func missingStore() throws {
        defer { removeStore() }
        _ = try Database.modelContainer(name: name, groupContainer: .none, allowsMigration: false)
        #expect(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)))
    }

    @Test("Core Fails With Empty Container If Store Is Outdated")
    func coreWithOutdatedStore() async throws {
        defer { removeStore() }
        try createOutdatedStore()
        let config = OutRunCoreConfiguration(containerName: name)
        let core = OutRunCore(config: config, syncServices: [], allowsMigration: false)
        guard case .failed(let error) = core.status, case OutRunCoreError.migrationRequired = error else {
            Issue.record("Unexpected status \(core.status)")
            return
        }
        #expect(core.modelContainer.configurations.allSatisfy { $0.isStoredInMemoryOnly })
        #expect(try ModelContext(core.modelContainer).fetchCount(FetchDescriptor<User>()) == 0)
        #expect(try storeVersions() == ["outdated"])
    }

    /// Uses Core Data as loading a previous schema while other suites use the current one can crash the test process.
    private func createOutdatedStore() throws {
        let attribute = NSAttributeDescription()
        attribute.name = "name"
        attribute.type = .string
        let entity = NSEntityDescription()
        entity.name = "User"
        entity.properties = [attribute]
        let model = NSManagedObjectModel()
        model.entities = [entity]
        model.versionIdentifiers = ["outdated"]
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let store = try coordinator.addPersistentStore(type: .sqlite, at: url)
        try coordinator.remove(store)
    }

    private func storeVersions() throws -> Set<String> {
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: url)
        return Set(metadata[NSStoreModelVersionIdentifiersKey] as? [String] ?? [])
    }

    private func removeStore() {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(atPath: url.path(percentEncoded: false) + suffix)
        }
    }
}
