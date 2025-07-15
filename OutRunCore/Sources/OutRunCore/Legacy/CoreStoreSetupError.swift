import CoreStore
import Foundation

/// An enumeration of possible errors coming up during the setup of data management.
enum CoreStoreSetupError: Error, CustomDebugStringConvertible {
    
    /// The DataStack could not be added.
    case failedToInitializeDataStack
    /// CoreStore failed to add the SQLiteStorage to the DataStack.
    case failedToAddStorage(error: CoreStoreError)
    
    var debugDescription: String {
        switch self {
        case .failedToInitializeDataStack: "The CoreStore DataStack could not be added."
        case .failedToAddStorage(let error): "CoreStore failed to add the SQLiteStorage to the DataStack: \(error.debugDescription)"
        }
    }
}
