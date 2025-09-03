//
//  HKWorkoutEventType.swift
//
//  OutRun
//  Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import HealthKit

extension HKWorkoutEventType {
    
    /// A boolean indicating whether the event type is a pause type.
    var isPauseType: Bool {
        switch self {
        case .pause, .motionPaused, .resume, .motionResumed:
            return true
        default:
            return false
        }
    }
    
    /// A custom raw value equivalent to raw values found in `WorkoutEvent.WorkoutEventType` and `WorkoutPause.WorkoutPauseType`.
    var convertedRawValue: Int {
        switch self {
        case .pause, .resume:
            return 0
        case .motionPaused, .motionResumed:
            return 1
        case .lap:
            return 0
        case .marker:
            return 1
        case .segment:
            return 2
        default:
            return -1
        }
    }
    
}
