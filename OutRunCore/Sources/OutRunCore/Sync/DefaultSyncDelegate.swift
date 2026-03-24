import Foundation

@BackgroundActor
class DefaultSyncDelegate: SyncDelegate {
    
    private let database: Database
    private let userDefaults: UserDefaults
    
    init(database: Database, userDefaults: UserDefaults) {
        self.database = database
        self.userDefaults = userDefaults
    }
    
    func insert(_ workout: RawWorkout) async throws -> UUID {
        try await database.insert(workout)
    }
    
    func update(_ workout: RawWorkout) async throws -> UUID {
        try await database.update(workout)
    }
    
    func delete(_ workout: RawWorkout) async throws {
        try await database.delete(workout)
    }
    
    nonisolated func setDevicePreference(_ value: Any, for key: String) {
        userDefaults.set(value, forKey: key)
    }
    
    nonisolated func devicePreference(for key: String) -> Any? {
        userDefaults.value(forKey: key)
    }
}
