//
//  TempV4.swift
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

enum TempV4 {
    
    class Workout: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let workoutType: OutRunV4.Workout.WorkoutType
        let distance: Double
        let steps: Int?
        let startDate: Date
        let endDate: Date
        let burnedEnergy: Double?
        let isRace: Bool
        let comment: String?
        let isUserModified: Bool
        let healthKitUUID: UUID?
        let finishedRecording: Bool
        
        let ascend: Double
        let descend: Double
        let activeDuration: Double
        let pauseDuration: Double
        let dayIdentifier: String
        
        let _heartRates: [TempV4.WorkoutHeartRateDataSample]
        let _routeData: [TempV4.WorkoutRouteDataSample]
        let _pauses: [TempV4.WorkoutPause]
        let _workoutEvents: [TempV4.WorkoutEvent]
        // events are not stored inside workout objects, instead the UUID of a workout is stored in the TempEvent object
        
        var heartRates: [ORWorkoutHeartRateDataSampleInterface] { _heartRates }
        var routeData: [ORWorkoutRouteDataSampleInterface] { _routeData }
        var pauses: [ORWorkoutPauseInterface] { _pauses }
        var workoutEvents: [ORWorkoutEventInterface] { _workoutEvents }
        var events: [OREventInterface] { throwOnAccess() }
        
        init(uuid: UUID?, workoutType: OutRunV4.Workout.WorkoutType, distance: Double, steps: Int?, startDate: Date, endDate: Date, burnedEnergy: Double?, isRace: Bool, comment: String?, isUserModified: Bool, healthKitUUID: UUID?, finishedRecording: Bool, ascend: Double, descend: Double, activeDuration: Double, pauseDuration: Double, dayIdentifier: String, heartRates: [TempV4.WorkoutHeartRateDataSample], routeData: [TempV4.WorkoutRouteDataSample], pauses: [TempV4.WorkoutPause], workoutEvents: [TempV4.WorkoutEvent]) {
            self.uuid = uuid
            self.workoutType = workoutType
            self.distance = distance
            self.steps = steps
            self.startDate = startDate
            self.endDate = endDate
            self.burnedEnergy = burnedEnergy
            self.isRace = isRace
            self.comment = comment
            self.isUserModified = isUserModified
            self.healthKitUUID = healthKitUUID
            self.finishedRecording = finishedRecording
            self.ascend = ascend
            self.descend = descend
            self.activeDuration = activeDuration
            self.pauseDuration = pauseDuration
            self.dayIdentifier = dayIdentifier
            self._heartRates = heartRates
            self._routeData = routeData
            self._pauses = pauses
            self._workoutEvents = workoutEvents
        }
        
        var asTemp: TempWorkout {
            return self
        }
    }

    class WorkoutPause: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let startDate: Date
        let endDate: Date
        let pauseType: OutRunV4.WorkoutPause.WorkoutPauseType

        init(uuid: UUID?, startDate: Date, endDate: Date, pauseType: OutRunV4.WorkoutPause.WorkoutPauseType) {
            self.uuid = uuid
            self.startDate = startDate
            self.endDate = endDate
            self.pauseType = pauseType
        }
        
        var asTemp: TempWorkoutPause {
            return self
        }
    }

    class WorkoutEvent: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let eventType: OutRunV4.WorkoutEvent.WorkoutEventType
        let timestamp: Date

        init(uuid: UUID?, eventType: OutRunV4.WorkoutEvent.WorkoutEventType, timestamp: Date) {
            self.uuid = uuid
            self.eventType = eventType
            self.timestamp = timestamp
        }
        
        var asTemp: TempWorkoutEvent {
            return self
        }
    }
    
    class WorkoutRouteDataSample: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let horizontalAccuracy: Double
        let verticalAccuracy: Double
        let speed: Double
        let direction: Double

        init(uuid: UUID?, timestamp: Date, latitude: Double, longitude: Double, altitude: Double, horizontalAccuracy: Double, verticalAccuracy: Double, speed: Double, direction: Double) {
            self.uuid = uuid
            self.timestamp = timestamp
            self.latitude = latitude
            self.longitude = longitude
            self.altitude = altitude
            self.horizontalAccuracy = horizontalAccuracy
            self.verticalAccuracy = verticalAccuracy
            self.speed = speed
            self.direction = direction
        }
        
        var asTemp: TempWorkoutRouteDataSample {
            return self
        }
    }
    
    class WorkoutHeartRateDataSample: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let heartRate: Int
        let timestamp: Date

        init(uuid: UUID?, heartRate: Int, timestamp: Date) {
            self.uuid = uuid
            self.heartRate = heartRate
            self.timestamp = timestamp
        }
        
        var asTemp: TempWorkoutHeartRateDataSample {
            return self
        }
    }
    
    class Event: Codable, TempValueConvertible {

        let uuid: UUID?
        let title: String
        let comment: String?
        let startDate: Date?
        let endDate: Date?
        let workouts: [UUID]

        init(uuid: UUID?, title: String, comment: String?, startDate: Date?, endDate: Date?, workouts: [UUID]) {
            self.uuid = uuid
            self.title = title
            self.comment = comment
            self.startDate = startDate
            self.endDate = endDate
            self.workouts = workouts
        }
        
        var asTemp: TempEvent {
            return self
        }
    }
    
}
