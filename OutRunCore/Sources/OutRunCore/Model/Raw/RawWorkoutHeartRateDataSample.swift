import Foundation

public struct RawWorkoutHeartRateDataSample: Codable, Equatable {
    
    public var heartRate: Int
    public var timestamp: Date
    
    public init(heartRate: Int, timestamp: Date) {
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
}
