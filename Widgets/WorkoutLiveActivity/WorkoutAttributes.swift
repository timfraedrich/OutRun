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

import ActivityKit
import Foundation
import OutRunCore

public struct WorkoutAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable, Sendable {
        public var type: WorkoutType
        public var isPaused: Bool
        public var duration: DynamicTimeInterval
        public var distance: Measurement<UnitLength>
        /// The preferences of the user recording the workout, used to display metrics in the preferred units.
        public var preferences: RawPreferences

        public init(
            type: WorkoutType,
            isPaused: Bool,
            duration: DynamicTimeInterval,
            distance: Measurement<UnitLength>,
            preferences: RawPreferences
        ) {
            self.type = type
            self.isPaused = isPaused
            self.duration = duration
            self.distance = distance
            self.preferences = preferences
        }
    }

    public init() {}
}
