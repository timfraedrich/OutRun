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
public class WorkoutHeartRateDataSample: WorkoutHeartRateDataSampleProtocol {
    
    public var heartRate: UInt8
    public var timestamp: Date
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(heartRate: UInt8, timestamp: Date, workout: Workout? = nil) {
        self.heartRate = heartRate
        self.timestamp = timestamp
        self.workout = workout
    }
    
    public convenience init(from sample: any WorkoutHeartRateDataSampleProtocol, attachTo workout: Workout? = nil) {
        self.init(heartRate: sample.heartRate, timestamp: sample.timestamp, workout: workout)
    }
}
