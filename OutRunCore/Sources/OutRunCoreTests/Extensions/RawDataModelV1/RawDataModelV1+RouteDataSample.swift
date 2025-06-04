import Foundation
@testable import OutRunDatabase

extension RawDataModelV1.RouteDataSample {
    
    init(from rawSample: RawWorkoutRouteDataSample) {
        self.init(
            uuid: rawSample.uuid,
            timestamp: rawSample.timestamp,
            latitude: rawSample.latitude,
            longitude: rawSample.longitude,
            altitude: rawSample.altitude,
            speed: rawSample.speed,
            direction: rawSample.direction
        )
    }
}