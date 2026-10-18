//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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
public class SyncServiceMapping: SyncServiceMappingProtocol {
    
    public var serviceIdentifier: String
    public var externalId: String?
    public var externalUrl: String?
    public var lastEditDateSynced: Date?
    public private(set) var rawSyncStatus: WorkoutSyncStatus.RawValue
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public var syncStatus: WorkoutSyncStatus {
        get { .init(rawValue: rawSyncStatus) }
        set { rawSyncStatus = newValue.rawValue }
    }
    
    public init(
        serviceIdentifier: String,
        externalId: String?,
        externalUrl: String?,
        lastEditDateSynced: Date?,
        syncStatus: WorkoutSyncStatus,
        workout: Workout? = nil
    ) {
        self.serviceIdentifier = serviceIdentifier
        self.externalId = externalId
        self.externalUrl = externalUrl
        self.lastEditDateSynced = lastEditDateSynced
        self.rawSyncStatus = syncStatus.rawValue
        self.workout = workout
    }
    
    public convenience init(from mapping: any SyncServiceMappingProtocol, attachTo workout: Workout? = nil) {
        self.init(
            serviceIdentifier: mapping.serviceIdentifier,
            externalId: mapping.externalId,
            externalUrl: mapping.externalUrl,
            lastEditDateSynced: mapping.lastEditDateSynced,
            syncStatus: mapping.syncStatus,
            workout: workout
        )
    }
}
