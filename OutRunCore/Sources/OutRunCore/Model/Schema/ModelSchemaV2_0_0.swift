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
@preconcurrency import SwiftData

/// The schema of existing stores, which is only used to migrate them.
/// - warning: These models must not be changed, otherwise existing stores will no longer be recognized.
enum ModelSchemaV2_0_0: VersionedSchema {

    static let versionIdentifier = Schema.Version(2, 0, 0)
    static let models: [any PersistentModel.Type] = [
        User.self,
        Workout.self,
        WorkoutRouteDataSample.self,
        WorkoutHeartRateDataSample.self,
        WorkoutPause.self,
        WorkoutEvent.self,
        SyncServiceMapping.self,
        SyncServiceState.self,
    ]

    @Model
    final class User {

        @Attribute(.unique, .preserveValueOnDeletion) var id: UUID?
        var name: String
        var rawBirthday: String?
        var weight: Double?
        var sex: Sex?
        var preferences: RawPreferences
        var creationDate: Date
        var lastEditDate: Date

        init(name: String, sex: Sex?, preferences: RawPreferences, creationDate: Date) {
            self.name = name
            self.sex = sex
            self.preferences = preferences
            self.creationDate = creationDate
            self.lastEditDate = creationDate
        }
    }

    @Model
    final class SyncServiceState {

        @Attribute(.unique) var id: String
        var lastSyncDate: Date?
        var lastSyncMode: SyncMode
        var preferences: RawPreferences

        init(id: String, lastSyncMode: SyncMode, preferences: RawPreferences) {
            self.id = id
            self.lastSyncMode = lastSyncMode
            self.preferences = preferences
        }
    }
}
