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

public struct RawWorkoutPause: Codable, Sendable, WorkoutPauseProtocol {
    
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    public init(startDate: Date, endDate: Date, userInitiated: Bool) {
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
    }
    
    public init(from pause: any WorkoutPauseProtocol) {
        self.init(
            startDate: pause.startDate,
            endDate: pause.endDate,
            userInitiated: pause.userInitiated
        )
    }
}
