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
public class WorkoutEvent: WorkoutEventProtocol {
    
    public private(set) var rawType: WorkoutEventType.RawValue
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public var type: WorkoutEventType {
        get { .init(rawValue: rawType) }
        set { rawType = newValue.rawValue }
    }
    
    public init(type: WorkoutEventType, timestamp: Date, workout: Workout? = nil) {
        self.rawType = type.rawValue
        self.timestamp = timestamp
        self.workout = workout
    }
    
    public convenience init(from event: any WorkoutEventProtocol, attachTo workout: Workout? = nil) {
        self.init(type: event.type, timestamp: event.timestamp, workout: workout)
    }
}
