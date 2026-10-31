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

enum ModelMigrationPlan: SchemaMigrationPlan {

    private static let migratedValueKey = "OutRunCore.migratedValue"

    static var schemas: [any VersionedSchema.Type] {
        [ModelSchemaV2_0_0.self, ModelSchemaV2_0_1.self]
    }

    static var stages: [MigrationStage] {
        [migrateV2ToCurrent]
    }

    /// Moves `User.sex` and `SyncServiceState.lastSyncMode` out of their composite attributes, because `fetchHistory` crashes on iOS 18 when
    /// reading updates to those. Lightweight migration cannot carry over their values, so they are kept in `preferences` during the stage.
    private static var migrateV2ToCurrent: MigrationStage {
        .custom(
            fromVersion: ModelSchemaV2_0_0.self,
            toVersion: ModelSchema.self,
            willMigrate: { context in
                for user in try context.fetch(FetchDescriptor<ModelSchemaV2_0_0.User>()) {
                    user.preferences[migratedValueKey] = user.sex.map { Data($0.rawValue.utf8) }
                }
                for state in try context.fetch(FetchDescriptor<ModelSchemaV2_0_0.SyncServiceState>()) {
                    state.preferences[migratedValueKey] = try JSONEncoder().encode(state.lastSyncMode)
                }
                try context.save()
            },
            didMigrate: { context in
                for user in try context.fetch(FetchDescriptor<User>()) {
                    guard let value = user.preferences.removeValue(forKey: migratedValueKey) else { continue }
                    user.sex = Sex(rawValue: String(decoding: value, as: UTF8.self))
                }
                for state in try context.fetch(FetchDescriptor<SyncServiceState>()) {
                    guard let value = state.preferences.removeValue(forKey: migratedValueKey) else { continue }
                    state.lastSyncMode = try JSONDecoder().decode(SyncMode.self, from: value)
                }
                try context.save()
            }
        )
    }
}
