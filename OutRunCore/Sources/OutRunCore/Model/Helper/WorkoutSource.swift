import Foundation

public enum WorkoutSource: Codable, Hashable, RawRepresentable, Sendable {
    
    case native
    case imported
    case manuallyEntered
    case syncService(identifier: String)
    case unknown(rawValue: String)
    
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
}
