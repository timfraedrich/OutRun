import Foundation

public enum OutRunCoreStatus: Equatable, Sendable {
    
    /// The core is currently being set up.
    case initializing
    /// The setup has not been performed. Required data for setup should be collected and ``OutRunCore/setup(for:)`` should be called.
    case needsSetup
    /// The core is fully initialized and ready for use.
    case initialized
    /// The core failed internally due to the provided error.
    case failed(Error)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing), (.needsSetup, .needsSetup), (.initialized, .initialized), (.failed, .failed): true
        default: false
        }
    }
}
