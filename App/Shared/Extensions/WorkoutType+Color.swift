import OutRunCore
import SwiftUI

extension WorkoutType {
    var color: Color {
        switch self {
        case .running: .orange
        case .walking: .green
        case .cycling: .blue
        case .skating: .purple
        case .hiking: .brown
        case .unknown: .gray
        }
    }
}
