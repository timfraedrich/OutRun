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

@BackgroundActor
class DefaultSyncDelegate: SyncDelegate {
    
    private let database: Database
    private let userDefaults: UserDefaults
    
    init(database: Database, userDefaults: UserDefaults) {
        self.database = database
        self.userDefaults = userDefaults
    }
    
    func upsert(_ workout: RawWorkout) async throws -> UUID {
        try await database.upsert(workout)
    }
    
    func delete(workoutWithIdentifier identifier: UUID, forServiceWith serviceIdentifier: String) async throws {
        try await database.delete(workoutWithIdentifier: identifier, forServiceWith: serviceIdentifier)
    }
    
    func delete(workoutWithExternalIdentifier externalIdentifier: String, forServiceWith serviceIdentifier: String) async throws {
        try await database.delete(workoutWithExternalIdentifier: externalIdentifier, forServiceWith: serviceIdentifier)
    }
    
    func delete(workoutWithExternalURL externalURL: String, forServiceWith serviceIdentifier: String) async throws {
        try await database.delete(workoutWithExternalURL: externalURL, forServiceWith: serviceIdentifier)
    }
    
    nonisolated func setDevicePreference(_ value: Any, for key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    nonisolated func devicePreference(for key: String) -> Any? {
        userDefaults.value(forKey: key)
    }
}
