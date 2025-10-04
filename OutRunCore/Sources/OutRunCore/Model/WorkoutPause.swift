import Foundation
import SwiftData

@Model
public class WorkoutPause: WorkoutPauseProtocol {
    
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public var duration: TimeInterval {
        startDate.distance(to: endDate)
    }
    
    public init(startDate: Date, endDate: Date, userInitiated: Bool, workout: Workout?) {
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
        self.workout = workout
    }
    
    public convenience init(from rawPause: RawWorkoutPause, attachTo workout: Workout? = nil) {
        self.init(startDate: rawPause.startDate, endDate: rawPause.endDate, userInitiated: rawPause.userInitiated, workout: workout)
    }
}
