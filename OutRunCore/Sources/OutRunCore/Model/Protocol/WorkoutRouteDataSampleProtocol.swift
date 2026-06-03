import CoreLocation
import Foundation

public protocol WorkoutRouteDataSampleProtocol: Equatable {
    var timestamp: Date { get }
    var latitude: Double { get }
    var longitude: Double { get }
    var altitude: Float { get }
    var horizontalAccuracy: Float { get }
    var verticalAccuracy: Float { get }
    var speed: Float { get }
}

public extension WorkoutRouteDataSampleProtocol {
    
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var validatedSpeed: Float? { speed >= 0 ? speed : nil }
    var validatedAltitude: Float? { verticalAccuracy > 0 ? altitude : nil }
}
