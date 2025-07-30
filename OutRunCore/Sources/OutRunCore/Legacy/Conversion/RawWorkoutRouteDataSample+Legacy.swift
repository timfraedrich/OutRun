import Foundation

extension RawWorkoutRouteDataSample {
    
    init(from routeDataSample: RawDataModelV1.RouteDataSample) {
        self.init(
            timestamp: routeDataSample.timestamp,
            latitude: routeDataSample.latitude,
            longitude: routeDataSample.longitude,
            altitude: Float(routeDataSample.altitude),
            horizontalAccuracy: .zero,
            verticalAccuracy: .zero,
            speed: Float(routeDataSample.speed)
        )
    }
    
    init(from routeDataSample: RawDataModelV2.RouteDataSample) {
        self.init(
            timestamp: routeDataSample.timestamp,
            latitude: routeDataSample.latitude,
            longitude: routeDataSample.longitude,
            altitude: Float(routeDataSample.altitude),
            horizontalAccuracy: Float(routeDataSample.horizontalAccuracy),
            verticalAccuracy: Float(routeDataSample.verticalAccuracy),
            speed: Float(routeDataSample.speed)
        )
    }
    
    init(from routeDataSample: RawDataModelV3.WorkoutRouteDataSample) {
        self.init(
            timestamp: routeDataSample.timestamp,
            latitude: routeDataSample.latitude,
            longitude: routeDataSample.longitude,
            altitude: Float(routeDataSample.altitude),
            horizontalAccuracy: Float(routeDataSample.horizontalAccuracy),
            verticalAccuracy: Float(routeDataSample.verticalAccuracy),
            speed: Float(routeDataSample.speed)
        )
    }
}
