import Foundation
import SwiftData

@Model
public class WorkoutHeartRateDataSample: Equatable {
    
    public var heartRate: UInt8
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout
    
    public init(heartRate: UInt8, timestamp: Date, workout: Workout) {
        self.heartRate = heartRate
        self.timestamp = timestamp
        self.workout = workout
    }
    
    convenience init(from rawHeartRateSample: RawWorkoutHeartRateDataSample, attachTo workout: Workout) {
        self.init(heartRate: rawHeartRateSample.heartRate, timestamp: rawHeartRateSample.timestamp, workout: workout)
    }
}
