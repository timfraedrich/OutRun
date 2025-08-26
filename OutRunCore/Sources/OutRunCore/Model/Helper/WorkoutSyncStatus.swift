import Foundation

public enum WorkoutSyncStatus: Codable, Equatable, Hashable, Sendable {
    case pending, synced, failed, conflict
}
