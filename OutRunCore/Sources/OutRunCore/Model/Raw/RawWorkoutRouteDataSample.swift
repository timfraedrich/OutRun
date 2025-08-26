import Foundation

public struct RawWorkoutRouteDataSample: Codable, Equatable, Sendable {
    
    public var timestamp: Date
    public var latitude: Double
    public var longitude: Double
    public var altitude: Float
    public var horizontalAccuracy: Float
    public var verticalAccuracy: Float
    public var speed: Float
    
    public init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitude: Float,
        horizontalAccuracy: Float,
        verticalAccuracy: Float,
        speed: Float
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
    }
    
    public init(from routeDataSample: WorkoutRouteDataSample) {
        self.init(
            timestamp: routeDataSample.timestamp,
            latitude: routeDataSample.latitude,
            longitude: routeDataSample.longitude,
            altitude: routeDataSample.altitude,
            horizontalAccuracy: routeDataSample.horizontalAccuracy,
            verticalAccuracy: routeDataSample.verticalAccuracy,
            speed: routeDataSample.speed
        )
    }
}
