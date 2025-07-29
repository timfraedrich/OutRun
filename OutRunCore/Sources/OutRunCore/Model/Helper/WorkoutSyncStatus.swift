import Foundation

public enum WorkoutSyncStatus: Codable, Equatable, Hashable {
    case pending, synced, failed, conflict
}
