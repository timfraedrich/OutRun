//
//  WorkoutEvent.swift
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

import Foundation
import HealthKit

typealias WorkoutEvent = OutRunV3.WorkoutEvent

extension WorkoutEvent: CustomStringConvertible {
    
    var description: String {
        return "WorkoutEvent(type: \(type.debugDescription), start: \(startDate.value), end: \(endDate.value)"
    }
    
    var type: WorkoutEventType {
        return WorkoutEventType(rawValue: self.eventType.value)
    }
    
    enum WorkoutEventType: CustomStringConvertible, CustomDebugStringConvertible {
        case pause, autoPause, resume, autoResume, lap, marker, segment, unknown
        
        init(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .pause
            case 1:
                self = .autoPause
            case 2:
                self = .resume
            case 3:
                self = .autoResume
            case 4:
                self = .lap
            case 5:
                self = .marker
            case 6:
                self = .segment
            default:
                self = .unknown
            }
        }
        
        init(healthType: HKWorkoutEventType) {
            switch healthType {
            case .pause:
                self = .pause
            case .motionPaused:
                self = .autoPause
            case .resume:
                self = .resume
            case .motionResumed:
                self = .autoResume
            case .lap:
                self = .lap
            case .marker:
                self = .marker
            case .segment:
                self = .segment
            default:
                self = .unknown
            }
        }
        
        var rawValue: Int {
            switch self {
            case .pause:
                return 0
            case .autoPause:
                return 1
            case .resume:
                return 2
            case .autoResume:
                return 3
            case .lap:
                return 4
            case .marker:
                return 5
            case .segment:
                return 6
            case .unknown:
                return -1
            }
        }
        
        var description: String {
            switch self {
            case .pause:
                return LS["WorkoutEvent.Type.Pause"]
            case .autoPause:
                return LS["WorkoutEvent.Type.AutoPause"]
            case .resume:
                return LS["WorkoutEvent.Type.Resume"]
            case .autoResume:
                return LS["WorkoutEvent.Type.AutoResume"]
            case .lap:
                return LS["WorkoutEvent.Type.Lap"]
            case .marker:
                return LS["WorkoutEvent.Type.Marker"]
            case .segment:
                return LS["WorkoutEvent.Type.Segment"]
            case .unknown:
                return LS["WorkoutEvent.Type.Unknown"]
            }
        }
        
        var debugDescription: String {
            switch self {
            case .pause:
                return "Pause"
            case .autoPause:
                return "Auto Pause"
            case .resume:
                return "Resume"
            case .autoResume:
                return "Auto Resume"
            case .lap:
                return "Lap"
            case .marker:
                return "Marker"
            case .segment:
                return "Segment"
            case .unknown:
                return "Unknown"
            }
        }
        
        var healthKitType: HKWorkoutEventType? {
            switch self {
            case .pause:
                return .pause
            case .autoPause:
                return .motionPaused
            case .resume:
                return .resume
            case .autoResume:
                return .motionResumed
            case .lap:
                return .lap
            case .marker:
                return .marker
            case .segment:
                return .segment
            case .unknown:
                return nil
            }
        }
    }
    
}
