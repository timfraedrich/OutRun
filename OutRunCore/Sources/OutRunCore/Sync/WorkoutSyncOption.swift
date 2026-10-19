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

/// A manual synchronisation that can be performed for a workout with a sync service.
public struct WorkoutSyncOption: Hashable, Sendable {
    
    public let serviceIdentifier: String
    public let action: Action
    
    public enum Action: Hashable, Sendable {
        /// The workout has not been synced to the service yet and can be synced to it for the first time.
        case initialOutwardSync
        /// The workout was previously synced to the service and can be synced to it again.
        case outwardResync
        /// The workout originates from the service and can be synced from it again, replacing the workout in the core.
        case inwardResync
    }
}
