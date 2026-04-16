import Foundation

public enum WorkoutRecorderError: LocalizedError, Equatable, CustomDebugStringConvertible {
    
    case alreadyRecording
    case inFailedState
    case notInitialized
    case notRecording
    case notPaused
    case alreadyPaused
    case locationAuthorizationInsufficient
    case invalidStatusTransition
    
    public var debugDescription: String {
        switch self {
        case .alreadyRecording: "WorkoutRecorderError.alreadyRecording"
        case .inFailedState: "WorkoutRecorderError.inFailedState"
        case .notInitialized: "WorkoutRecorderError.notInitialized"
        case .notRecording: "WorkoutRecorderError.notRecording"
        case .notPaused: "WorkoutRecorderError.notPaused"
        case .alreadyPaused: "WorkoutRecorderError.alreadyPaused"
        case .locationAuthorizationInsufficient: "WorkoutRecorderError.locationAuthorizationInsufficient"
        case .invalidStatusTransition: "WorkoutRecorderError.invalidStatusTransition"
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .alreadyRecording: .init(localized: "workout_recorder_error_already_recording", bundle: .module)
        case .inFailedState: .init(localized: "workout_recorder_error_in_failed_state", bundle: .module)
        case .notInitialized: .init(localized: "workout_recorder_error_not_initialized", bundle: .module)
        case .notRecording: .init(localized: "workout_recorder_error_not_recording", bundle: .module)
        case .notPaused: .init(localized: "workout_recorder_error_not_paused", bundle: .module)
        case .alreadyPaused: .init(localized: "workout_recorder_error_already_paused", bundle: .module)
        case .locationAuthorizationInsufficient: .init(localized: "workout_recorder_error_location_authorization_insufficient", bundle: .module)
        case .invalidStatusTransition: .init(localized: "workout_recorder_error_invalid_status_transition", bundle: .module)
        }
    }
}
