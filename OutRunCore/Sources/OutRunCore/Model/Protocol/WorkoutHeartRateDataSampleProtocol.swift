import Foundation

public protocol WorkoutHeartRateDataSampleProtocol: Equatable {
    var heartRate: UInt8 { get }
    var timestamp: Date { get }
}