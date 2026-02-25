import Foundation

public enum SyncMode: Codable, Hashable, Sendable {
    /// No workouts or their changes should be synced to the service.
    case disabled
    /// All workouts and their changes should be synced to the service.
    case enabled
    /// Workouts and their changes should be synced to the service if the workout was created after the specified date.
    case enabledFrom(date: Date)
}
