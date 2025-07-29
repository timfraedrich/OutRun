import Foundation

public enum WorkoutService: Codable, Equatable, Hashable {
    
    case appleHealth
    case imported
    case manuallyEntered
    case native
    
    var sourceEditingAllowed: Bool {
        switch self {
        case .appleHealth: return false
        case .imported, .manuallyEntered, .native: return false
        }
    }
}
