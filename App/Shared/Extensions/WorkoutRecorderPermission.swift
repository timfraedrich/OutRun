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

import OutRunCore
import SwiftUI

extension WorkoutRecorderPermission {

    var systemImage: String {
        switch self {
        case .location: "location.fill"
        case .motionAndFitness: "figure.walk.motion"
        }
    }

    var reason: LocalizedStringKey {
        switch self {
        case .location: "permission_location_reason"
        case .motionAndFitness: "permission_motion_and_fitness_reason"
        }
    }

    func resolution(for status: PermissionStatus) -> LocalizedStringKey {
        switch (self, status) {
        case (.location, .limited): "permission_location_limited_resolution"
        case (.location, _): "permission_location_denied_resolution"
        case (.motionAndFitness, _): "permission_motion_and_fitness_denied_resolution"
        }
    }
}
