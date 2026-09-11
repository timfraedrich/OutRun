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
