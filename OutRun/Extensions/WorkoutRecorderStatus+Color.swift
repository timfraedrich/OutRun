import OutRunCore
import SwiftUI

extension WorkoutRecorderStatus {
    var color: Color {
        switch self {
        case .idle: .green
        case .recording: .red
        case .failed, .initializing, .paused: .gray
        }
    }
}
