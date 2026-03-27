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
    
    func delete(workoutWithIdentifier identifier: UUID) async throws {
        try await database.delete(workoutWithIdentifier: identifier)
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
