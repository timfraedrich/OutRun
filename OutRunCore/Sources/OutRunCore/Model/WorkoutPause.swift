import Foundation
import SwiftData

@Model
public class WorkoutPause: Equatable, Identifiable {
    
    @Attribute(.unique) public var id: UUID
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(id: UUID = .init(), startDate: Date, endDate: Date, userInitiated: Bool) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
    }
}
