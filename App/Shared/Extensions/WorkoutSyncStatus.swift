import OutRunCore
import SwiftUI

extension WorkoutSyncStatus {
    
    var localized: String {
        switch self {
        case .pending: .init(localized: "workout_sync_status_pending")
        case .synced: .init(localized: "workout_sync_status_synced")
        case .failed: .init(localized: "workout_sync_status_failed")
        case .conflict: .init(localized: "workout_sync_status_conflict")
        case .unknown(let rawValue): .init(localized: "workout_sync_status_unknown_\(rawValue)")
        }
    }
    
    var systemImage: String {
        switch self {
        case .pending: "ellipsis.circle.fill"
        case .synced: "checkmark.circle.fill"
        case .failed: "exclamationmark.circle.fill"
        case .conflict: "bolt.circle.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: .gray
        case .synced: .green
        case .failed, .conflict, .unknown: .red
        }
    }
}
