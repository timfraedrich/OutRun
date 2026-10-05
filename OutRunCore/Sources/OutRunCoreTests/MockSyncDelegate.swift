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
