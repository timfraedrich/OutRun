import CoreLocation
import Foundation

public protocol WorkoutRouteDataSampleProtocol: Equatable {
    var timestamp: Date { get }
    var latitude: Double { get }
    var longitude: Double { get }
    var altitude: Float { get }
    /// - note: This value is only valid if it is greater than zero.
    var horizontalAccuracy: Float { get }
    /// - note: This value is only valid if it is greater than zero.
    var verticalAccuracy: Float { get }
    /// - note: This value is only valid if it is greater or equal to zero.
    var speed: Float { get }
}

public extension WorkoutRouteDataSampleProtocol {
    
    static var invalidSpeed: Float { -1 }
    static var invalidHorizontalAccuracy: Float { 0 }
    static var invalidVerticalAccuracy: Float { 0 }
    
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var validatedSpeed: Float? { speed >= 0 ? speed : nil }
    var validatedAltitude: Float? { verticalAccuracy > 0 ? altitude : nil }
}
