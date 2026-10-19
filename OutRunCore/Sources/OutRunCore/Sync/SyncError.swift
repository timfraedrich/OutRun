//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
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
    /// The exact version of the workout is already present, so it was skipped.
    case alreadyUpToDate
    /// The workout cannot be synced as it is still being recorded.
    case workoutNotFinished
    /// The workout cannot be synced to the service, for example because it originates from another service.
    case workoutNotSyncable
    /// The workout could not be found on the service, for example because it was deleted there.
    case workoutNotFoundOnService
    
    public var errorDescription: String? {
        switch self {
        case .conflict: .init(localized: "sync_error_conflict", bundle: .module)
        case .serviceUnavailable: .init(localized: "sync_error_service_unavailable", bundle: .module)
        case .authenticationRequired: .init(localized: "sync_error_authentication_required", bundle: .module)
        case .networkError: .init(localized: "sync_error_network_error", bundle: .module)
        case .unknown: .init(localized: "sync_error_unknown", bundle: .module)
        case .alreadyUpToDate: .init(localized: "sync_error_already_up_to_date", bundle: .module)
        case .workoutNotFinished: .init(localized: "sync_error_workout_not_finished", bundle: .module)
        case .workoutNotSyncable: .init(localized: "sync_error_workout_not_syncable", bundle: .module)
        case .workoutNotFoundOnService: .init(localized: "sync_error_workout_not_found_on_service", bundle: .module)
        }
    }
}
