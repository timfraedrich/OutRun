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
    
    @Relationship(deleteRule: .nullify) public var workout: Workout
    
    public init(
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitude: Float,
        horizontalAccuracy: Float,
        verticalAccuracy: Float,
        speed: Float,
        workout: Workout
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
    
    convenience init(from rawRouteSample: RawWorkoutRouteDataSample, attachTo workout: Workout) {
        self.init(
            timestamp: rawRouteSample.timestamp,
            latitude: rawRouteSample.latitude,
            longitude: rawRouteSample.longitude,
            altitude: rawRouteSample.altitude,
            horizontalAccuracy: rawRouteSample.horizontalAccuracy,
            verticalAccuracy: rawRouteSample.verticalAccuracy,
            speed: rawRouteSample.speed,
            workout: workout
        )
    }
    
    convenience init(from location: CLLocation, attachTo workout: Workout) {
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
