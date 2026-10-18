//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
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

import CoreLocation

public extension CLLocation {
    
    convenience init(routeSample: any WorkoutRouteDataSampleProtocol) {
        self.init(
            coordinate: routeSample.coordinate,
            altitude: Double(routeSample.altitude),
            horizontalAccuracy: Double(routeSample.horizontalAccuracy),
            verticalAccuracy: Double(routeSample.verticalAccuracy),
            course: -1,
            courseAccuracy: -1,
            speed: Double(routeSample.speed),
            speedAccuracy: 0,
            timestamp: routeSample.timestamp
        )
    }
}
