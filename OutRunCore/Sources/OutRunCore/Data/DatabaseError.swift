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

enum DatabaseError: LocalizedError, CustomDebugStringConvertible {
    
    /// The object was not found in the database.
    case objectNotFound
    /// The function ``Database/continueWorkout(with:continueDate:)`` was called on a workout that has not been finished.
    case workoutNotFinished
    /// Functions meant for manipulation during recording were called after a workout had already been finished.
    case workoutAlreadyFinished
    /// The user cannot be inserted into the database as there already is a user object present.
    case userAlreadyPresent
    
    var debugDescription: String {
        switch self {
        case .objectNotFound: "DatabaseError.objectNotFound"
        case .workoutNotFinished: "DatabaseError.workoutNotFinished"
        case .workoutAlreadyFinished: "DatabaseError.workoutAlreadyFinished"
        case .userAlreadyPresent: "DatabaseError.userAlreadyPresent"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .objectNotFound: .init(localized: "database_error_object_not_found", bundle: .module)
        case .workoutNotFinished: .init(localized: "database_error_workout_not_finished", bundle: .module)
        case .workoutAlreadyFinished: .init(localized: "database_error_workout_already_finished", bundle: .module)
        case .userAlreadyPresent: .init(localized: "database_error_user_already_present", bundle: .module)
        }
    }
}
