import Foundation

public struct RawWorkoutHeartRateDataSample: Codable, Equatable, Sendable {
    
    public var heartRate: UInt8
    public var timestamp: Date
    
    public init(heartRate: UInt8, timestamp: Date) {
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
    
    public init(from heartRateSample: WorkoutHeartRateDataSample) {
        self.init(
            heartRate: heartRateSample.heartRate,
            timestamp: heartRateSample.timestamp
        )
    }
}
