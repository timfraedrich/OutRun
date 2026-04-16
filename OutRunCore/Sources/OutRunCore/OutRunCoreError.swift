import Foundation

// TODO: Finish Localization
public enum OutRunCoreError: CustomDebugStringConvertible, LocalizedError {
    
    case invalidNameProvided
    case notInitialized
    case setupNotRequired
    case newerWorkoutVersionExists
    
    public var debugDescription: String {
        switch self {
        case .invalidNameProvided: "OutRunCoreError.invalidNameProvided"
        case .notInitialized: "OutRunCoreError.notInitialized"
        case .setupNotRequired: "OutRunCoreError.setupNotRequired"
        case .newerWorkoutVersionExists: "OutRunCoreError.newerWorkoutVersionExists"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .invalidNameProvided: .init(localized: "core_error_invalid_name_provided", bundle: .module)
        case .notInitialized: .init(localized: "core_error_not_initialized", bundle: .module)
        case .setupNotRequired: .init(localized: "core_error_setup_not_required", bundle: .module)
        case .newerWorkoutVersionExists: ""
        }
    }
}
