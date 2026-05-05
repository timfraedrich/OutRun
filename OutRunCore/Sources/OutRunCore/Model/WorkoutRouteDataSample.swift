import CoreLocation
import Foundation
import SwiftData

@Model
public class WorkoutRouteDataSample: WorkoutRouteDataSampleProtocol {
    
    public var timestamp: Date
    public var latitude: Double
    public var longitude: Double
    public var altitude: Float
    public var horizontalAccuracy: Float
    public var verticalAccuracy: Float
    public var speed: Float
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitude: Float,
        horizontalAccuracy: Float,
        verticalAccuracy: Float,
        speed: Float,
        workout: Workout? = nil
    ) {
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
        self.workout = workout
    }
    
    public convenience init(from sample: any WorkoutRouteDataSampleProtocol, attachTo workout: Workout? = nil) {
        self.init(
            timestamp: sample.timestamp,
            latitude: sample.latitude,
            longitude: sample.longitude,
            altitude: sample.altitude,
            horizontalAccuracy: sample.horizontalAccuracy,
            verticalAccuracy: sample.verticalAccuracy,
            speed: sample.speed,
            workout: workout
        )
    }
    
    public convenience init(from location: CLLocation, attachTo workout: Workout? = nil) {
        self.init(
            timestamp: location.timestamp,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: Float(location.altitude),
            horizontalAccuracy: Float(location.horizontalAccuracy),
            verticalAccuracy: Float(location.verticalAccuracy),
            speed: Float(location.speed),
            workout: workout
        )
    }
}
