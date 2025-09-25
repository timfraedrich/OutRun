import Foundation

public enum OutRunCoreStatus: Equatable, Sendable {
    
    /// The core is currently being set up.
    case initializing
    /// There is currently no user configured. Required data for setup should be collected and ``OutRunCore/createUser()`` should be called.
    case userMissing
    /// The core is fully initialized and ready for use.
    case initialized
    /// The core failed internally due to the provided error.
    case failed(Error)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing), (.initialized, .initialized), (.failed, .failed): true
        default: false
        }
    }
}
