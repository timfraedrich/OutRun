import Foundation

public struct RawWorkoutPause: Codable, Sendable, WorkoutPauseProtocol {
    
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    public init(startDate: Date, endDate: Date, userInitiated: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
    }
    
    public init(from pause: any WorkoutPauseProtocol) {
        self.init(
            startDate: pause.startDate,
            endDate: pause.endDate,
            userInitiated: pause.userInitiated
        )
    }
}
