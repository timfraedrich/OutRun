import MapKit
import SwiftUI

public struct WorkoutRouteMap: View {
    
    @Environment(\.self) var environment
    private let coordinates: [CLLocationCoordinate2D]
    private let showUserLocation: Bool
    
    public var body: some View {
        Map(position: .constant(showUserLocation ? .userLocation(fallback: .automatic) : .automatic)) {
            if showUserLocation {
                UserAnnotation()
            }
            if !coordinates.isEmpty {
                MapPolyline(coordinates: coordinates, contourStyle: .geodesic)
                    .stroke(.tint, style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
        }
    }
    
    public init(coordinates: [CLLocationCoordinate2D], showUserLocation: Bool = false) {
        self.coordinates = coordinates
        self.showUserLocation = showUserLocation
    }
    
    public init(workout: any WorkoutProtocol, showUserLocation: Bool = false) {
        self.init(coordinates: workout.route.map { $0.coordinate }, showUserLocation: showUserLocation)
    }
}

#Preview {
    WorkoutRouteMap(coordinates: PreviewConstants.coordinates)
}
