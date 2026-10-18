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
public class WorkoutPause: WorkoutPauseProtocol {
    
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(startDate: Date, endDate: Date, userInitiated: Bool, workout: Workout?) {
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
        self.workout = workout
    }
    
    public convenience init(from pause: any WorkoutPauseProtocol, attachTo workout: Workout? = nil) {
        self.init(startDate: pause.startDate, endDate: pause.endDate, userInitiated: pause.userInitiated, workout: workout)
    }
}
