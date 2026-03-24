import Foundation

/// Protocol that exposes synchronization functionality from an external service to the core.
public protocol SyncDelegate: AnyObject, Sendable {
    
    /// Called when a workout was created and should be synced to the core.
    /// - returns: The identifier of the workout saved in the core.
    func insert(_ workout: RawWorkout) async throws -> UUID
    
    /// Called when a workout was updated and should be synced to the core.
    /// - returns: The identifier of the workout updated in the core.
    func update(_ workout: RawWorkout) async throws -> UUID
    
    /// Called when a workout was deleted and should be synced to the core.
    func delete(_ workout: RawWorkout) async throws
    
    /// Sets a value to the appropriate UserDefaults.
    func setDevicePreference(_ value: Any, for key: String)
    
    /// Retrives a value from the appropriate UserDefaults.
    func devicePreference(for key: String) -> Any?
}
