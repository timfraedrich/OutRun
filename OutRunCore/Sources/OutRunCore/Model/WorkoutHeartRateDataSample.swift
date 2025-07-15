import Foundation
import SwiftData

@Model
public class WorkoutHeartRateDataSample: Equatable, Identifiable {
    
    @Attribute(.unique) public var id: UUID
    public var heartRate: Int
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(id: UUID = .init(), heartRate: Int, timestamp: Date) {
        self.id = id
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
}
