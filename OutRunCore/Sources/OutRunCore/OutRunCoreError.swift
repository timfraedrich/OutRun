import Foundation

public enum OutRunCoreError: CustomDebugStringConvertible, LocalizedError {
    
    case notInitialized
    case userNotMissing
    
    public var debugDescription: String {
        switch self {
        case .notInitialized: "OutRunCoreError.notInitialized"
        case .userNotMissing: "OutRunCoreError.userNotMissing"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized: R.string.localizable.core_error_not_initialized()
        case .userNotMissing: R.string.localizable.core_error_user_not_missing()
        }
    }
}
