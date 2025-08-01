import Foundation

public struct RawWorkoutPause: Codable, Equatable {
    
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    public var duration: TimeInterval {
        startDate.distance(to: endDate)
    }
    
    public init(startDate: Date, endDate: Date, userInitiated: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
    }
    
    public init(from workoutPause: WorkoutPause) {
        self.init(
            startDate: workoutPause.startDate,
            endDate: workoutPause.endDate,
            userInitiated: workoutPause.userInitiated
        )
    }
}
