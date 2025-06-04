import CoreStore
import Foundation

/// An enumeration of possible errors coming up during the saving process of an object by the `DataManager`.
enum CoreStoreSaveError: Error, CustomDebugStringConvertible {
    
    /// The object already exists inside the database.
    case alreadySaved
    /// The object could not be validated.
    case notValid
    /// There was an error while trying to insert the object into the database.
    case databaseError(error: CoreStoreError)
    
    var debugDescription: String {
        switch self {
        case .alreadySaved: "The object already exists inside the database."
        case .notValid: "The object could not be validated"
        case .databaseError(let error):
            "There was an error while trying to insert the object into the database: \(error.debugDescription)"
        }
    }
}
