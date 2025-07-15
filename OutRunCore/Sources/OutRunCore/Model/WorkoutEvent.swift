import Foundation
import SwiftData

@Model
public class WorkoutEvent: Equatable, Identifiable {
    
    @Attribute(.unique) public var id: UUID
    public var type: WorkoutEventType
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(id: UUID = .init(), type: WorkoutEventType, timestamp: Date) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
    }
}
