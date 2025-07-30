import Foundation

extension RawWorkoutHeartRateDataSample {
    
    init(from heartRateDataSample: RawDataModelV3.WorkoutHeartRateDataSample) {
        self.init(heartRate: UInt8(heartRateDataSample.heartRate), timestamp: heartRateDataSample.timestamp)
    }
}
