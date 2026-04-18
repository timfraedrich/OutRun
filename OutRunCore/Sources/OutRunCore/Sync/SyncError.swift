import Foundation

public enum SyncError: LocalizedError {
    
    /// The workout has conflicting changes. Requires manual user intervention.
    case conflict
    /// The sync service is temporarily unavailable. Will retry on next sync attempt.
    case serviceUnavailable
    /// The sync service requires re-authentication or setup.
    case authenticationRequired
    /// A network error occurred while communicating with the service.
    case networkError
    /// An unknown error occurred during sync.
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .conflict: .init(localized: "sync_error_conflict", bundle: .module)
        case .serviceUnavailable: .init(localized: "sync_error_service_unavailable", bundle: .module)
        case .authenticationRequired: .init(localized: "sync_error_authentication_required", bundle: .module)
        case .networkError: .init(localized: "sync_error_network_error", bundle: .module)
        case .unknown: .init(localized: "sync_error_unknown", bundle: .module)
        }
    }
}
