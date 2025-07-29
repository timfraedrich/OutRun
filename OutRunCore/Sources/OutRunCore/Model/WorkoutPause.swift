import Foundation
import SwiftData

@Model
public class WorkoutPause: Equatable {
    
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(startDate: Date, endDate: Date, userInitiated: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
    }
}
