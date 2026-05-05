import Foundation
import SwiftData

@Model
public class WorkoutEvent: WorkoutEventProtocol {
    
    public private(set) var rawType: WorkoutEventType.RawValue
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public var type: WorkoutEventType {
        get { .init(rawValue: rawType) }
        set { rawType = newValue.rawValue }
    }
    
    public init(type: WorkoutEventType, timestamp: Date, workout: Workout? = nil) {
        self.rawType = type.rawValue
        self.timestamp = timestamp
        self.workout = workout
    }
    
    public convenience init(from event: any WorkoutEventProtocol, attachTo workout: Workout? = nil) {
        self.init(type: event.type, timestamp: event.timestamp, workout: workout)
    }
}
