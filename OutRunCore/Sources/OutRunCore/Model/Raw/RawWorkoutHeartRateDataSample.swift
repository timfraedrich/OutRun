import Foundation

public struct RawWorkoutHeartRateDataSample: Codable, Sendable, WorkoutHeartRateDataSampleProtocol {
    
    public var heartRate: UInt8
    public var timestamp: Date
    
    public init(heartRate: UInt8, timestamp: Date) {
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
    
    public init(from sample: any WorkoutHeartRateDataSampleProtocol) {
        self.init(
            heartRate: sample.heartRate,
            timestamp: sample.timestamp
        )
    }
}
