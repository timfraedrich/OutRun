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
        case .alreadyRecording: .init(localized: "workout_recorder_error_already_recording")
        case .inFailedState: .init(localized: "workout_recorder_error_in_failed_state")
        case .notInitialized: .init(localized: "workout_recorder_error_not_initialized")
        case .notRecording: .init(localized: "workout_recorder_error_not_recording")
        case .notPaused: .init(localized: "workout_recorder_error_not_paused")
        case .alreadyPaused: .init(localized: "workout_recorder_error_already_paused")
        case .locationAuthorizationInsufficient: .init(localized: "workout_recorder_error_location_authorization_insufficient")
        case .invalidStatusTransition: .init(localized: "workout_recorder_error_invalid_status_transition")
        }
    }
}
