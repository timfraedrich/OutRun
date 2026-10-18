//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
