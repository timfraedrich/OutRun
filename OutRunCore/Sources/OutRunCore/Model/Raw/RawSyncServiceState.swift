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

import Foundation

struct RawSyncServiceState {
    
    var id: String
    var lastSyncDate: Date?
    var lastSyncMode: SyncMode
    var preferences: RawPreferences
    
    init(id: String, lastSyncDate: Date? = nil, lastSyncMode: SyncMode = .disabled, preferences: RawPreferences = .init()) {
        self.id = id
        self.lastSyncDate = lastSyncDate
        self.lastSyncMode = lastSyncMode
        self.preferences = preferences
    }
    
    init(from state: SyncServiceState) {
        self.init(id: state.id, lastSyncDate: state.lastSyncDate, lastSyncMode: state.lastSyncMode, preferences: state.preferences)
    }
}
