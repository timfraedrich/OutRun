import Foundation
import SwiftData

@Model
public class WorkoutHeartRateDataSample: Equatable {
    
    public var heartRate: Int
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(heartRate: Int, timestamp: Date) {
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
}
