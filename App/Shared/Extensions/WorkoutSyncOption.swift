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

extension WorkoutSyncOption {
    
    private var serviceName: String {
        WorkoutSource.syncService(identifier: serviceIdentifier).localizedShortName
    }
    
    var titleKey: LocalizedStringKey {
        switch action {
        case .initialOutwardSync: "sync_action_save_to_\(serviceName)"
        case .outwardResync: "sync_action_save_again_to_\(serviceName)"
        case .inwardResync: "sync_action_import_again_from_\(serviceName)"
        }
    }
    
    var systemImage: String {
        switch action {
        case .initialOutwardSync, .outwardResync: "arrow.up.circle"
        case .inwardResync: "arrow.down.circle"
        }
    }
    
    var conflictMessageKey: LocalizedStringKey {
        switch action {
        case .initialOutwardSync, .outwardResync: "sync_conflict_outward_message_\(serviceName)"
        case .inwardResync: "sync_conflict_inward_message_\(serviceName)"
        }
    }
    
    var conflictConfirmationKey: LocalizedStringKey {
        switch action {
        case .initialOutwardSync, .outwardResync: "sync_conflict_save_anyway"
        case .inwardResync: "sync_conflict_import_anyway"
        }
    }
}
