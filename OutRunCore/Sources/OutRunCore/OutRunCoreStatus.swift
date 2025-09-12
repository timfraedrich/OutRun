import Foundation

public enum OutRunCoreStatus: Equatable, Sendable {
    
    case initializing
    case initialized
    case failed(Error)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing), (.initialized, .initialized), (.failed, .failed): true
        default: false
        }
    }
}
