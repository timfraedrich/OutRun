import Foundation

public enum WorkoutRecorderStatus: Equatable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
    
    /// Preparing functionality.
    case initializing
    /// Ready to start recording, given that location access was provided.
    case idle
    /// Currently recording.
    case recording
    /// Currently recording, but not adding to distance or time. Boolean value indicates whether the pause was user initiated.
    case paused(manual: Bool)
    /// Failed with the specified error.
    case failed(Error)
    
    public var description: String {
        switch self {
        case .initializing: .init(localized: "workout_recorder_status_initializing")
        case .idle: .init(localized: "workout_recorder_status_idle")
        case .recording: .init(localized: "workout_recorder_status_recording")
        case .paused(let manual):
            if manual {
                .init(localized: "workout_recorder_status_paused_manual")
            } else {
                .init(localized: "workout_recorder_status_paused_automatic")
            }
        case .failed: .init(localized: "workout_recorder_status_failed")
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .initializing: "WorkoutRecorderStatus.initializing"
        case .idle: "WorkoutRecorderStatus.idle"
        case .recording: "WorkoutRecorderStatus.recording"
        case .paused(manual: let manual): "WorkoutRecorderStatus.paused(manual: \(manual))"
        case .failed(let error): "WorkoutRecorderStatus.failed(\((error as CustomDebugStringConvertible).debugDescription))"
        }
    }
    
    public var isCollectingData: Bool {
        switch self {
        case .recording, .paused: true
        default: false
        }
    }
    
    public var isPaused: Bool {
        switch self {
        case .paused: true
        default: false
        }
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing), (.idle, .idle), (.recording, .recording), (.failed, .failed): true
        case (.paused(let lhsManual), .paused(manual: let rhsManual)): lhsManual == rhsManual
        default: false
        }
    }
}
