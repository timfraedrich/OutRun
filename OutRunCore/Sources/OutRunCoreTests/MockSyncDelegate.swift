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
    
    func insert(_ workout: RawWorkout) async throws -> UUID {
        try await defaultSyncDelegate.insert(workout)
    }
    
    func update(_ workout: RawWorkout) async throws -> UUID {
        try await defaultSyncDelegate.update(workout)
    }
    
    func delete(_ workout: RawWorkout) async throws {
        try await defaultSyncDelegate.delete(workout)
    }
    
    nonisolated func setDevicePreference(_ value: Any, for key: String) {
        keyValueStorage[key] = value
    }
    
    nonisolated func devicePreference(for key: String) -> Any? {
        keyValueStorage[key]
    }
}
