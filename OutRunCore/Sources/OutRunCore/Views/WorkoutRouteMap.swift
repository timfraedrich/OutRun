//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
