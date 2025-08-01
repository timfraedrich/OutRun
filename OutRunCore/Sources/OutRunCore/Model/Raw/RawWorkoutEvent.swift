import Foundation

public struct RawWorkoutEvent: Codable, Equatable {
    
    public var type: WorkoutEventType
    public var timestamp: Date
    
    public init(type: WorkoutEventType, timestamp: Date) {
        self.type = type
        self.timestamp = timestamp
    }
    
    public init(from workoutEvent: WorkoutEvent) {
        self.init(type: workoutEvent.type, timestamp: workoutEvent.timestamp)
    }
}
