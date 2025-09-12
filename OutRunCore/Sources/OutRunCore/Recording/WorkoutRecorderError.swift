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
            case .alreadyRecording: R.string.localizable.workout_recorder_error_already_recording()
            case .inFailedState: R.string.localizable.workout_recorder_error_in_failed_state()
            case .notInitialized: R.string.localizable.workout_recorder_error_not_initialized()
            case .notRecording: R.string.localizable.workout_recorder_error_not_recording()
            case .notPaused: R.string.localizable.workout_recorder_error_not_paused()
            case .alreadyPaused: R.string.localizable.workout_recorder_error_already_paused()
            case .locationAuthorizationInsufficient: R.string.localizable.workout_recorder_error_location_authorization_insufficient()
            case .invalidStatusTransition: R.string.localizable.workout_recorder_error_invalid_status_transition()
            }
        }
    }
