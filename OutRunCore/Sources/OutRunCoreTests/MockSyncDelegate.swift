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

/// This class is supposed to call the DefaultSyncDelegate for inbound sync operations while emulating UserDefault persistence without
/// calls to the actual UserDefaults class.
@BackgroundActor
class MockSyncDelegate: SyncDelegate {
    
    private let defaultSyncDelegate: DefaultSyncDelegate
    nonisolated(unsafe) var keyValueStorage: [String: Any] = [:]
    
    init(database: Database) {
        self.defaultSyncDelegate = .init(database: database, userDefaults: .standard)
    }
    
    func upsert(_ workout: RawWorkout) async throws -> UUID {
        try await defaultSyncDelegate.upsert(workout)
    }
    
    func delete(workoutWithIdentifier identifier: UUID, forServiceWith serviceIdentifier: String) async throws {
        try await defaultSyncDelegate.delete(workoutWithIdentifier: identifier, forServiceWith: serviceIdentifier)
    }
    
    func delete(workoutWithExternalIdentifier externalIdentifier: String, forServiceWith serviceIdentifier: String) async throws {
        try await defaultSyncDelegate.delete(workoutWithExternalIdentifier: externalIdentifier, forServiceWith: serviceIdentifier)
    }
    
    func delete(workoutWithExternalURL externalURL: String, forServiceWith serviceIdentifier: String) async throws {
        try await defaultSyncDelegate.delete(workoutWithExternalURL: externalURL, forServiceWith: serviceIdentifier)
    }
    
    nonisolated func setDevicePreference(_ value: Any, for key: String) {
        keyValueStorage[key] = value
    }
    
    nonisolated func devicePreference(for key: String) -> Any? {
        keyValueStorage[key]
    }
}
