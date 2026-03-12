import Foundation

public enum WorkoutSyncStatus: Codable, Hashable, RawRepresentable, Sendable {
    
    case pending
    case synced
    case failed
    case conflict
    case unknown(rawValue: String)
    
    static var casesWhereSyncShouldBeAttempted: [Self] { [.pending, .failed] }
    
    // MARK: RawRepresentable
    
    public init(rawValue: String) {
        self = switch rawValue {
        case "pending": .pending
        case "synced": .synced
        case "failed": .failed
        case "conflict": .conflict
        default: .unknown(rawValue: rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .pending: "pending"
        case .synced: "synced"
        case .failed: "failed"
        case .conflict: "conflict"
        case .unknown(let rawValue): rawValue
        }
    }
}
