import Foundation
import SwiftData

@Model
public class WorkoutPause: WorkoutPauseProtocol {
    
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(startDate: Date, endDate: Date, userInitiated: Bool, workout: Workout?) {
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
        self.workout = workout
    }
    
    public convenience init(from pause: any WorkoutPauseProtocol, attachTo workout: Workout? = nil) {
        self.init(startDate: pause.startDate, endDate: pause.endDate, userInitiated: pause.userInitiated, workout: workout)
    }
}
