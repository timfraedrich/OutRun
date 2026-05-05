import CoreLocation
import Foundation

public struct RawWorkoutRouteDataSample: Codable, Sendable, WorkoutRouteDataSampleProtocol {
    
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
    
    public init(from sample: any WorkoutRouteDataSampleProtocol) {
        self.init(
            timestamp: sample.timestamp,
            latitude: sample.latitude,
            longitude: sample.longitude,
            altitude: sample.altitude,
            horizontalAccuracy: sample.horizontalAccuracy,
            verticalAccuracy: sample.verticalAccuracy,
            speed: sample.speed
        )
    }
    
    public init(from location: CLLocation) {
        self.init(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: Float(location.altitude),
            horizontalAccuracy: Float(location.horizontalAccuracy),
            verticalAccuracy: Float(location.verticalAccuracy),
            speed: Float(location.speed)
        )
    }
}
