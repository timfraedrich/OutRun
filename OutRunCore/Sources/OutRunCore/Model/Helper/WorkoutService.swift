import Foundation

public enum WorkoutSource: Codable, Equatable, Hashable, Sendable {
    
    case native
    case imported
    case manuallyEntered
    case syncService(identifier: String)
}
