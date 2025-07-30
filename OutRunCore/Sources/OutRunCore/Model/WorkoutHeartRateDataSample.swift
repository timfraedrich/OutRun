import Foundation
import SwiftData

@Model
public class WorkoutHeartRateDataSample: Equatable {
    
    public var heartRate: UInt8
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(heartRate: UInt8, timestamp: Date) {
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
}
