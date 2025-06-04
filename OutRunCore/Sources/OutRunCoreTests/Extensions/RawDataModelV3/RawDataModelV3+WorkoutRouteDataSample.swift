import Foundation
@testable import OutRunDatabase

extension RawDataModelV3.WorkoutRouteDataSample {
    
    init(from rawSample: RawWorkoutRouteDataSample) {
        self.init(
            uuid: rawSample.uuid,
            timestamp: rawSample.timestamp,
            latitude: rawSample.latitude,
            longitude: rawSample.longitude,
            altitude: rawSample.altitude,
            horizontalAccuracy: rawSample.horizontalAccuracy,
            verticalAccuracy: rawSample.verticalAccuracy,
            speed: rawSample.speed,
            direction: rawSample.direction
        )
    }
}