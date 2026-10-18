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

public struct RawWorkoutEvent: Codable, Sendable, WorkoutEventProtocol {
    
    public var type: WorkoutEventType
    public var timestamp: Date
    
    public init(type: WorkoutEventType, timestamp: Date) {
        self.type = type
        self.timestamp = timestamp
    }
    
    public init(from event: any WorkoutEventProtocol) {
        self.init(type: event.type, timestamp: event.timestamp)
    }
}
