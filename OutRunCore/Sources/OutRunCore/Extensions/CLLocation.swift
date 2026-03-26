import CoreLocation

public extension CLLocation {
    
    convenience init(routeSample: any WorkoutRouteDataSampleProtocol) {
        self.init(
            coordinate: routeSample.coordinate,
            altitude: Double(routeSample.altitude),
            horizontalAccuracy: Double(routeSample.horizontalAccuracy),
            verticalAccuracy: Double(routeSample.verticalAccuracy),
            course: -1,
            courseAccuracy: -1,
            speed: Double(routeSample.speed),
            speedAccuracy: 0,
            timestamp: routeSample.timestamp
        )
    }
}
