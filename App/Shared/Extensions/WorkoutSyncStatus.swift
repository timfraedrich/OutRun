//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
