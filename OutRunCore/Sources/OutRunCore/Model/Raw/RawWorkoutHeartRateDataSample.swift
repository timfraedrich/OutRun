import Foundation

public struct RawWorkoutHeartRateDataSample: Codable, Equatable {
    
    public var uuid: UUID
    public var heartRate: Int
    public var timestamp: Date
    
    public init(uuid: UUID, heartRate: Int, timestamp: Date) {
        self.uuid = uuid
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
}
