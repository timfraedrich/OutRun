import Foundation

public enum WorkoutSource: Codable, Hashable, RawRepresentable, Sendable, CustomStringConvertible {
    
    case native
    case imported
    case manuallyEntered
    case syncService(identifier: String)
    case unknown(rawValue: String)
    
    /// Indicates whether a workout with this source should be synced to sync services.
    /// - note: For now the only workouts that are synced outward are the ones recorded, imported or entered with this library.
    var shouldSyncOutward: Bool {
        switch self {
        case .native, .imported, .manuallyEntered: true
        case .syncService, .unknown: false
        }
    }
    
    // MARK: RawRepresentable
    
    public init(rawValue: String) {
        switch rawValue {
        case "native": self = .native
        case "imported": self = .imported
        case "manuallyEntered": self = .manuallyEntered
        case let value where value.hasPrefix("syncService:"):
            let identifier = String(value.dropFirst("syncService:".count))
            self = .syncService(identifier: identifier)
        default: self = .unknown(rawValue: rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .native: "native"
        case .imported: "imported"
        case .manuallyEntered: "manuallyEntered"
        case .syncService(let identifier): "syncService:\(identifier)"
        case .unknown(let rawValue): rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .native: .init(localized: "workout_source_native", bundle: .module)
        case .imported: .init(localized: "workout_source_imported", bundle: .module)
        case .manuallyEntered: .init(localized: "workout_source_manually_entered", bundle: .module)
        case .syncService(let identifier): .init(localized: "workout_source_sync_service_\(identifier)", bundle: .module)
        case .unknown(let rawValue): .init(localized: "workout_source_unknown_\(rawValue)", bundle: .module)
        }
    }
}
