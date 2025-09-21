import MapKit
import SwiftUI

public struct WorkoutRouteMap: View {
    
    @Environment(\.self) var environment
    private let coordinates: [CLLocationCoordinate2D]
    private let strokeColor: Color
    
    public var body: some View {
        Map(position: .constant(.userLocation(fallback: .automatic))) {
            UserAnnotation()
            if !coordinates.isEmpty {
                MapPolyline(coordinates: coordinates, contourStyle: .geodesic)
                    .stroke(strokeColor.resolve(in: environment), style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
        }
    }
    
    /// - note: Due to a bug in SwiftUI the stroke color of the route must be set manually rather than taken from the environment.
    public init(coordinates: [CLLocationCoordinate2D], strokeColor: Color = .accentColor) {
        self.coordinates = coordinates
        self.strokeColor = strokeColor
    }
    
    /// - note: Due to a bug in SwiftUI the stroke color of the route must be set manually rather than taken from the environment.
    public init(workout: any WorkoutProtocol, strokeColor: Color = .accentColor) {
        self.init(coordinates: workout.route.map { $0.coordinate }, strokeColor: strokeColor)
    }
}

#Preview {
    WorkoutRouteMap(coordinates: PreviewConstants.coordinates)
}
