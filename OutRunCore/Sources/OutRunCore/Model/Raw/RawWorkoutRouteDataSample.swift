import Foundation

public struct RawWorkoutRouteDataSample: Codable, Equatable {
    
    public var uuid: UUID
    public var timestamp: Date
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
    public var horizontalAccuracy: Double
    public var verticalAccuracy: Double
    public var speed: Double
    public var direction: Double
    
    public init(
        uuid: UUID,
        timestamp: Date,
        latitude: Double,
        longitude: Double,
        altitude: Double,
        horizontalAccuracy: Double,
        verticalAccuracy: Double,
        speed: Double,
        direction: Double
    ) {
        self.uuid = uuid
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
