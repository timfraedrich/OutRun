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
import SwiftData

@Model
class SyncServiceState {
    
    @Attribute(.unique) var id: String
    var lastSyncDate: Date?
    private(set) var rawLastSyncMode: String?
    private(set) var rawLastSyncModeDate: Date?
    var preferences: RawPreferences

    var lastSyncMode: SyncMode {
        get { Self.syncMode(from: rawLastSyncMode, and: rawLastSyncModeDate) }
        set { (rawLastSyncMode, rawLastSyncModeDate) = Self.rawSyncMode(from: newValue) }
    }
    
    init(id: String, lastSyncDate: Date? = nil, lastSyncMode: SyncMode = .disabled, preferences: RawPreferences = .init()) {
        self.id = id
        self.lastSyncDate = lastSyncDate
        self.preferences = preferences
        (rawLastSyncMode, rawLastSyncModeDate) = Self.rawSyncMode(from: lastSyncMode)
    }
    
    convenience init(from rawState: RawSyncServiceState) {
        self.init(
            id: rawState.id,
            lastSyncDate: rawState.lastSyncDate,
            lastSyncMode: rawState.lastSyncMode,
            preferences: rawState.preferences
        )
    }

    static func rawSyncMode(from syncMode: SyncMode) -> (String, Date?) {
        (syncMode.identifier, syncMode.date)
    }

    static func syncMode(from rawSyncMode: String?, and rawSyncModeDate: Date?) -> SyncMode {
        .init(identifier: rawSyncMode, date: rawSyncModeDate) ?? .disabled
    }
}
