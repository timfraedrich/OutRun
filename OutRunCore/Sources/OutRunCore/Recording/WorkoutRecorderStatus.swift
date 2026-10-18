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
        case .initializing: .init(localized: "workout_recorder_status_initializing", bundle: .module)
        case .idle: .init(localized: "workout_recorder_status_idle", bundle: .module)
        case .recording: .init(localized: "workout_recorder_status_recording", bundle: .module)
        case .paused(let manual):
            if manual {
                .init(localized: "workout_recorder_status_paused_manual", bundle: .module)
            } else {
                .init(localized: "workout_recorder_status_paused_automatic", bundle: .module)
            }
        case .failed: .init(localized: "workout_recorder_status_failed", bundle: .module)
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
