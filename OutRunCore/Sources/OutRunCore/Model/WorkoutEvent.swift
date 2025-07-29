import Foundation
import SwiftData

@Model
public class WorkoutEvent: Equatable {
    
    public var type: WorkoutEventType
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(type: WorkoutEventType, timestamp: Date) {
        self.type = type
        self.timestamp = timestamp
    }
}
