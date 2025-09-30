import MapKit
import SwiftUI

public struct WorkoutRouteMap: View {
    
    @Environment(\.self) var environment
    private let coordinates: [CLLocationCoordinate2D]
    private let strokeColor: Color
    private let showUserLocation: Bool
    
    public var body: some View {
        Map(position: .constant(showUserLocation ? .userLocation(fallback: .automatic) : .automatic)) {
            if showUserLocation {
                UserAnnotation()
            }
            if !coordinates.isEmpty {
                MapPolyline(coordinates: coordinates, contourStyle: .geodesic)
                    .stroke(strokeColor.resolve(in: environment), style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
        }
    }
    
    /// - note: Due to a bug in SwiftUI the stroke color of the route must be set manually rather than taken from the environment.
    public init(coordinates: [CLLocationCoordinate2D], strokeColor: Color = .accentColor, showUserLocation: Bool = false) {
        self.coordinates = coordinates
        self.strokeColor = strokeColor
        self.showUserLocation = showUserLocation
    }
    
    /// - note: Due to a bug in SwiftUI the stroke color of the route must be set manually rather than taken from the environment.
    public init(workout: any WorkoutProtocol, strokeColor: Color = .accentColor, showUserLocation: Bool = false) {
        self.init(coordinates: workout.route.map { $0.coordinate }, strokeColor: strokeColor, showUserLocation: showUserLocation)
    }
}

#Preview {
    WorkoutRouteMap(coordinates: PreviewConstants.coordinates)
}
