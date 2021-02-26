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
import CoreStore

typealias WorkoutEvent = OutRunV4.WorkoutEvent

extension WorkoutEvent: CustomStringConvertible {
    
    var description: String {
        var desc = "WorkoutEvent("
            
        if let uuid = uuid {
            desc += "uuid: \(uuid), "
        }
        
        return desc + "type: \(eventType.debugDescription), timestamp: \(timestamp)"
    }
    
    enum WorkoutEventType: CustomStringConvertible, CustomDebugStringConvertible, RawRepresentable, ImportableAttributeType, Codable {
        case lap, marker, segment, unknown
        
        init(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .lap
            case 1:
                self = .marker
            case 2:
                self = .segment
            default:
                self = .unknown
            }
        }
        
        init?(healthType: HKWorkoutEventType) {
            switch healthType {
            case .lap:
                self = .lap
            case .marker:
                self = .marker
            case .segment:
                self = .segment
            default:
                return nil
            }
        }
        
        var rawValue: Int {
            switch self {
            case .lap:
                return 0
            case .marker:
                return 1
            case .segment:
                return 2
            case .unknown:
                return -1
            }
        }
        
        var description: String {
            switch self {
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
