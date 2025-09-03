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
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
