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
        case .objectNotFound: R.string.localizable.database_error_object_not_found()
        case .workoutNotFinished: R.string.localizable.database_error_workout_not_finished()
        case .workoutAlreadyFinished: R.string.localizable.database_error_workout_already_finished()
        case .userAlreadyPresent: R.string.localizable.database_error_user_already_present()
        }
    }
}
