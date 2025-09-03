import Foundation
import OutRunCore

extension RawWorkoutHeartRateDataSample {
    
    init(from heartRateDataSample: LegacyRawDataModelV3.WorkoutHeartRateDataSample) {
        self.init(heartRate: UInt8(heartRateDataSample.heartRate), timestamp: heartRateDataSample.timestamp)
    }
}
