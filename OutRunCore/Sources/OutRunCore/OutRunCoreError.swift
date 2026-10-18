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

public enum OutRunCoreError: CustomDebugStringConvertible, LocalizedError {
    
    /// The provided name during setup is invalid.
    case invalidNameProvided
    /// The action is not possible as the core is not yet initialized.
    case notInitialized
    /// Setup cannot be performed as the core was already set up.
    case setupNotRequired
    /// The workout could not be upserted as a newer version already exists in the database.
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
        case .newerWorkoutVersionExists: .init(localized: "core_error_newer_workout_version_exists", bundle: .module)
        }
    }
}
