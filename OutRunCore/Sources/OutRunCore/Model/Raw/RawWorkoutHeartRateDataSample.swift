import Foundation

public struct RawWorkoutHeartRateDataSample: Codable, Equatable {
    
    public var heartRate: UInt8
    public var timestamp: Date
    
    public init(heartRate: UInt8, timestamp: Date) {
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
}
