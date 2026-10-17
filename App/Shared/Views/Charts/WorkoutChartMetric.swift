import SwiftUI

enum WorkoutChartMetric: CaseIterable, Hashable {
    
    case speed, altitude, heartRate
    
    var stringKey: LocalizedStringKey {
        switch self {
        case .altitude: "altitude"
        case .speed: "speed"
        case .heartRate: "heart_rate"
        }
    }
}
