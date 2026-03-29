import Foundation

/// Enum whose cases indicate whether and if so since when changes should be synchronized.
public enum SyncMode: Codable, Hashable, Sendable {
    
    /// No workouts or their changes should be synced to the service.
    case disabled
    /// All workouts and their changes should be synced to the service.
    case enabled
    /// Workouts and their changes should be synced to the service if the workout was created after the specified date.
    case enabledFrom(date: Date)
    
    var isEnabled: Bool {
        switch self {
        case .enabled, .enabledFrom: true
        case .disabled: false
        }
    }
    
    var startDate: Date? {
        switch self {
        case .disabled: nil
        case .enabled: .distantPast
        case .enabledFrom(let date): date
        }
    }
}
