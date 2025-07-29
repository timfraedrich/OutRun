import Foundation

public struct RawWorkoutEvent: Codable, Equatable {
    
    public var type: WorkoutEventType
    public var timestamp: Date
    
    public init(type: WorkoutEventType, timestamp: Date) {
        self.type = type
        self.timestamp = timestamp
    }
}
