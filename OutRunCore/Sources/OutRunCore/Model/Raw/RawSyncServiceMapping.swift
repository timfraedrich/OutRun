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

public struct RawSyncServiceMapping: Codable, Equatable, Sendable, SyncServiceMappingProtocol {
    
    public var serviceIdentifier: String
    public var externalId: String?
    public var externalUrl: String?
    public var lastEditDateSynced: Date?
    public var syncStatus: WorkoutSyncStatus
    
    public init(
        serviceIdentifier: String,
        externalId: String? = nil,
        externalUrl: String? = nil,
        lastEditDateSynced: Date? = nil,
        syncStatus: WorkoutSyncStatus = .pending
    ) {
        self.serviceIdentifier = serviceIdentifier
        self.externalId = externalId
        self.externalUrl = externalUrl
        self.lastEditDateSynced = lastEditDateSynced
        self.syncStatus = syncStatus
    }
    
    public init(from mapping: any SyncServiceMappingProtocol) {
        self.init(
            serviceIdentifier: mapping.serviceIdentifier,
            externalId: mapping.externalId,
            externalUrl: mapping.externalUrl,
            lastEditDateSynced: mapping.lastEditDateSynced,
            syncStatus: mapping.syncStatus
        )
    }
}
