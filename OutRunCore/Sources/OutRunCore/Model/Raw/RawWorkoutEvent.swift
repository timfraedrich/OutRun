import Foundation

public struct RawWorkoutEvent: Codable, Equatable {
    
    public var uuid: UUID
    public var eventType: WorkoutEventType
    public var timestamp: Date
    
    public init(uuid: UUID, eventType: WorkoutEventType, timestamp: Date) {
        self.uuid = uuid
        self.eventType = eventType
        self.timestamp = timestamp
    }
}
