import Foundation
import SwiftData

@Model
public class WorkoutRouteDataSample: Equatable, Identifiable {
    
    @Attribute(.unique) public private(set) var id: UUID
    public var timestamp: Date
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var horizontalAccuracy: Double
    public var verticalAccuracy: Double
    public var speed: Double
    public var direction: Double
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(
        id: UUID = .init(),
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitude: Double,
        horizontalAccuracy: Double,
        verticalAccuracy: Double,
        speed: Double,
        direction: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
        self.direction = direction
    }
}
