import Foundation

public enum OutRunCoreError: CustomDebugStringConvertible, LocalizedError {
    
    case invalidNameProvided
    case notInitialized
    case setupNotRequired
    
    public var debugDescription: String {
        switch self {
        case .invalidNameProvided: "OutRunCoreError.invalidNameProvided"
        case .notInitialized: "OutRunCoreError.notInitialized"
        case .setupNotRequired: "OutRunCoreError.setupNotRequired"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidNameProvided: R.string.localizable.core_error_invalid_name_provided()
        case .notInitialized: R.string.localizable.core_error_not_initialized()
        case .setupNotRequired: R.string.localizable.core_error_setup_not_required()
        }
    }
}
