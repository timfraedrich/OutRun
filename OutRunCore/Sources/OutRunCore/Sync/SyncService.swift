import Foundation
import HealthKit

public protocol SyncService: AnyObject, Sendable {
    
    var identifier: String { get }
    
    var relevantAttributes: Set<PartialKeyPath<Workout> & Sendable> { get }
    
    var mode: SyncMode { get async }
    
    func initialize(with delegate: any SyncDelegate) async throws
    
    func deinitialize() async
    
    /// Called when a workout was created or updated and should be synced to the service.
    /// - returns: An identifier or URL to the workout for the external service.
    /// - note: This function may be called multiple times with the same workout data. If the exact workout data was previously synced, the
    /// request can just be ignored, but the correct id or url should still be returned.
    func upsert(_ workout: RawWorkout) async throws -> (id: String?, url: String?)
    
    /// Called when a workout was deleted and should be synced to the service.
    /// - note: This function may be called for identifiers whose corresponding workouts were never synced to the service or already
    /// deleted. This case should be treated as success with no error being thrown.
    func delete(workoutWith identifier: UUID) async throws
}
