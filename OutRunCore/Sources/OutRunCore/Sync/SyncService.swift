import Foundation
import HealthKit

public protocol SyncService: AnyObject, Sendable {
    
    var identifier: String { get }
    
    var relevantAttributes: Set<PartialKeyPath<Workout> & Sendable> { get }
    
    var mode: SyncMode { get async }
    
    func initialize(with delegate: any SyncDelegate) async throws
    
    func deinitialize() async
    
    /// Called when a workout was created and should be synced to the service.
    /// - returns: An identifier or URL to the workout for the external service.
    func insert(_ workout: RawWorkout) async throws -> (id: String?, url: String?)
    
    /// Called when a workout was updated and should be synced to the service.
    /// - returns: An identifier or URL to the workout for the external service.
    func update(_ workout: RawWorkout) async throws -> (id: String?, url: String?)
    
    /// Called when a workout was deleted and should be synced to the service.
    func delete(workoutWith identifier: UUID) async throws
}
