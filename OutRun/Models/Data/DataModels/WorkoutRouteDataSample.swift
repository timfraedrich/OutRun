//
//  RouteDataSample.swift
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
import CoreLocation

public typealias WorkoutRouteDataSample = OutRunV4.WorkoutRouteDataSample

// MARK: - CustomStringConvertible

extension WorkoutRouteDataSample: CustomStringConvertible {
    
    public var description: String {
        
        var desc = "RouteDataSample("
        
        if let uuid = uuid {
            desc += "uuid: \(uuid), "
        }
        
        return desc + "latitude: \(latitude), longitude: \(longitude), altitude: \(altitude), direction: \(direction), speed: \(speed), timeStamp: \(timestamp))"
    }
    
}

// MARK: - ORWorkoutRouteDataSampleInterface

extension WorkoutRouteDataSample: ORWorkoutRouteDataSampleInterface {
    
    public var uuid: UUID? { threadSafeSyncReturn { self._uuid.value } }
    public var timestamp: Date { threadSafeSyncReturn { self._timestamp.value } }
    public var latitude: Double { threadSafeSyncReturn { self._latitude.value } }
    public var longitude: Double { threadSafeSyncReturn { self._longitude.value } }
    public var altitude: Double { threadSafeSyncReturn { self._altitude.value } }
    public var horizontalAccuracy: Double { threadSafeSyncReturn { self._horizontalAccuracy.value } }
    public var verticalAccuracy: Double { threadSafeSyncReturn { self._verticalAccuracy.value } }
    public var speed: Double { threadSafeSyncReturn { self._speed.value } }
    public var direction: Double { threadSafeSyncReturn { self._direction.value } }
    public var workout: ORWorkoutInterface? { threadSafeSyncReturn { self._workout.value } }
    
}

// MARK: - TempValueConvertible

extension WorkoutRouteDataSample: TempValueConvertible {
    
    public var asTemp: TempWorkoutRouteDataSample {
        TempWorkoutRouteDataSample(
            uuid: uuid,
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            speed: speed,
            direction: direction
        )
    }
    
}
