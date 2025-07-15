import CoreStore
import Foundation

/// An enumeration of possible errors coming up during the extraction of workouts for migration to SwiftData.
enum CoreStoreExtractionError: Error, CustomDebugStringConvertible {
    
    /// The database model is not current, it should be migrated to the most recent version before attempting to extract all data.
    case invalidModel
    /// There was an error while trying to extract all objects from the database.
    case databaseError(error: CoreStoreError)
    
    var debugDescription: String {
        switch self {
        case .invalidModel: "The CoreStore database model is not current, it should be migrated to the most recent version before attempting to extract all data."
        case .databaseError(let error):
            "There was an error while trying to extract all objects from the CoreStore database.: \(error.debugDescription)"
        }
    }
}
