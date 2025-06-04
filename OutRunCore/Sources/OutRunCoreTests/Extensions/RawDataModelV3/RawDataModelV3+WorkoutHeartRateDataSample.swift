import Foundation
@testable import OutRunDatabase

extension RawDataModelV3.WorkoutHeartRateDataSample {
    
    init(from rawSample: RawWorkoutHeartRateDataSample) {
        self.init(
            uuid: rawSample.uuid,
            heartRate: Double(rawSample.heartRate),
            timestamp: rawSample.timestamp
        )
    }
}