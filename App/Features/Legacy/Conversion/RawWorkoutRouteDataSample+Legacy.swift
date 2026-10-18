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

import Foundation
import OutRunCore

extension RawWorkoutRouteDataSample {
    
    init(from routeDataSample: LegacyRawDataModelV1.RouteDataSample) {
        self.init(
            timestamp: routeDataSample.timestamp,
            latitude: routeDataSample.latitude,
            longitude: routeDataSample.longitude,
            altitude: Float(routeDataSample.altitude),
            horizontalAccuracy: .zero,
            verticalAccuracy: .zero,
            speed: Float(routeDataSample.speed)
        )
    }
    
    init(from routeDataSample: LegacyRawDataModelV2.RouteDataSample) {
        self.init(
            timestamp: routeDataSample.timestamp,
            latitude: routeDataSample.latitude,
            longitude: routeDataSample.longitude,
            altitude: Float(routeDataSample.altitude),
            horizontalAccuracy: Float(routeDataSample.horizontalAccuracy),
            verticalAccuracy: Float(routeDataSample.verticalAccuracy),
            speed: Float(routeDataSample.speed)
        )
    }
    
    init(from routeDataSample: LegacyRawDataModelV3.WorkoutRouteDataSample) {
        self.init(
            timestamp: routeDataSample.timestamp,
            latitude: routeDataSample.latitude,
            longitude: routeDataSample.longitude,
            altitude: Float(routeDataSample.altitude),
            horizontalAccuracy: Float(routeDataSample.horizontalAccuracy),
            verticalAccuracy: Float(routeDataSample.verticalAccuracy),
            speed: Float(routeDataSample.speed)
        )
    }
}
