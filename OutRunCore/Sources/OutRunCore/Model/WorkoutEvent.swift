import Foundation
import SwiftData

@Model
public class WorkoutEvent: WorkoutEventProtocol {
    
    public var type: WorkoutEventType
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(type: WorkoutEventType, timestamp: Date, workout: Workout) {
        self.type = type
        self.timestamp = timestamp
        self.workout = workout
    }
    
    public convenience init(from rawEvent: RawWorkoutEvent, attachTo workout: Workout) {
        self.init(type: rawEvent.type, timestamp: rawEvent.timestamp, workout: workout)
    }
}
