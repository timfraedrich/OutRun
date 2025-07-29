import Foundation
import SwiftData

@Model
public class WorkoutRouteDataSample: Equatable {
    
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
}
