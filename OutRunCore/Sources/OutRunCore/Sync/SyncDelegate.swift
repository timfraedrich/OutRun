import Foundation

/// Protocol that exposes synchronization functionality from an external service to the core.
public protocol SyncDelegate: AnyObject, Sendable {
    
    /// Called when a workout was created or updated and should be synced to the core.
    /// - returns: The identifier of the workout saved in the core.
    @discardableResult
    func upsert(_ workout: RawWorkout) async throws -> UUID
    
    /// Called when a workout was deleted and should be synced to the core.
    /// - parameter identifier: The identifier of the workout from the core.
    func delete(workoutWithIdentifier identifier: UUID) async throws
    
    /// Called when a workout was deleted and should be synced to the core.
    /// - parameter externalIdentifier: The identifier of the workout from an external service.
    /// - note: The delegate will attempt to find the workout by locating a SyncServiceMapping that has the assigned id.
    func delete(workoutWithExternalIdentifier externalIdentifier: String, forServiceWith serviceIdentifier: String) async throws
    
    /// Called when a workout was deleted and should be synced to the core.
    /// - parameter externalURL: The url to the workout from an external service.
    /// - note: The delegate will attempt to find the workout by locating a SyncServiceMapping that has the assigned id.
    func delete(workoutWithExternalURL externalURL: String, forServiceWith serviceIdentifier: String) async throws
    
    /// Sets a value to the appropriate UserDefaults.
    func setDevicePreference(_ value: Any, for key: String)
    
    /// Retrives a value from the appropriate UserDefaults.
    func devicePreference(for key: String) -> Any?
}
