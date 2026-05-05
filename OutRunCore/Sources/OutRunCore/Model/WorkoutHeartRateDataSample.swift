import Foundation
import SwiftData

@Model
public class WorkoutHeartRateDataSample: WorkoutHeartRateDataSampleProtocol {
    
    public var heartRate: UInt8
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(heartRate: UInt8, timestamp: Date, workout: Workout? = nil) {
        self.heartRate = heartRate
        self.timestamp = timestamp
        self.workout = workout
    }
    
    public convenience init(from sample: any WorkoutHeartRateDataSampleProtocol, attachTo workout: Workout? = nil) {
        self.init(heartRate: sample.heartRate, timestamp: sample.timestamp, workout: workout)
    }
}
