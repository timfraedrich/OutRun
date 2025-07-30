import CoreStore
import Foundation

/// An enumeration of possible errors coming up during the insertion of legacy data models into legacy data management.
enum CoreStoreInsertionError: Error, CustomDebugStringConvertible {
    
    /// There was an error while trying to insert the object into the database.
    case databaseError(error: CoreStoreError)
    
    var debugDescription: String {
        switch self {
        case .databaseError(let error):
            "There was an error while trying to insert the object into the CoreStore database: \(error.debugDescription)"
        }
    }
}
