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

public enum TempV4 {
    
    public class Workout: Codable, TempValueConvertible {
        
        public var uuid: UUID?
        public var workoutType: OutRunV4.Workout.WorkoutType
        public var distance: Double
        public var steps: Int?
        public var startDate: Date
        public var endDate: Date
        public var burnedEnergy: Double?
        public var isRace: Bool
        public var comment: String?
        public var isUserModified: Bool
        public var healthKitUUID: UUID?
        public var finishedRecording: Bool
        
        public var ascend: Double
        public var descend: Double
        public var activeDuration: Double
        public var pauseDuration: Double
        public var dayIdentifier: String
        
        var _heartRates: [TempV4.WorkoutHeartRateDataSample]
        var _routeData: [TempV4.WorkoutRouteDataSample]
        var _pauses: [TempV4.WorkoutPause]
        var _workoutEvents: [TempV4.WorkoutEvent]
        // events are not stored inside workout objects, instead the UUID of a workout is stored in the TempEvent object
        
        public var heartRates: [ORWorkoutHeartRateDataSampleInterface] { _heartRates }
        public var routeData: [ORWorkoutRouteDataSampleInterface] { _routeData }
        public var pauses: [ORWorkoutPauseInterface] { _pauses }
        public var workoutEvents: [ORWorkoutEventInterface] { _workoutEvents }
        public var events: [OREventInterface] { throwOnAccess() }
        
        public init(uuid: UUID?, workoutType: OutRunV4.Workout.WorkoutType, distance: Double, steps: Int?, startDate: Date, endDate: Date, burnedEnergy: Double?, isRace: Bool, comment: String?, isUserModified: Bool, healthKitUUID: UUID?, finishedRecording: Bool, ascend: Double, descend: Double, activeDuration: Double, pauseDuration: Double, dayIdentifier: String, heartRates: [TempV4.WorkoutHeartRateDataSample], routeData: [TempV4.WorkoutRouteDataSample], pauses: [TempV4.WorkoutPause], workoutEvents: [TempV4.WorkoutEvent]) {
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
        
        public var asTemp: TempWorkout {
            return self
        }
    }

    public class WorkoutPause: Codable, TempValueConvertible {
        
        public var uuid: UUID?
        public var startDate: Date
        public var endDate: Date
        public var pauseType: OutRunV4.WorkoutPause.WorkoutPauseType

        public init(uuid: UUID?, startDate: Date, endDate: Date, pauseType: OutRunV4.WorkoutPause.WorkoutPauseType) {
            self.uuid = uuid
            self.startDate = startDate
            self.endDate = endDate
            self.pauseType = pauseType
        }
        
        public var asTemp: TempWorkoutPause {
            return self
        }
    }

    public class WorkoutEvent: Codable, TempValueConvertible {
        
        public var uuid: UUID?
        public var eventType: OutRunV4.WorkoutEvent.WorkoutEventType
        public var timestamp: Date

        public init(uuid: UUID?, eventType: OutRunV4.WorkoutEvent.WorkoutEventType, timestamp: Date) {
            self.uuid = uuid
            self.eventType = eventType
            self.timestamp = timestamp
        }
        
        public var asTemp: TempWorkoutEvent {
            return self
        }
    }
    
    public class WorkoutRouteDataSample: Codable, TempValueConvertible {
        
        public var uuid: UUID?
        public var timestamp: Date
        public var latitude: Double
        public var longitude: Double
        public var altitude: Double
        public var horizontalAccuracy: Double
        public var verticalAccuracy: Double
        public var speed: Double
        public var direction: Double

        public init(uuid: UUID?, timestamp: Date, latitude: Double, longitude: Double, altitude: Double, horizontalAccuracy: Double, verticalAccuracy: Double, speed: Double, direction: Double) {
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
        
        public var asTemp: TempWorkoutRouteDataSample {
            return self
        }
    }
    
    public class WorkoutHeartRateDataSample: Codable, TempValueConvertible {
        
        public var uuid: UUID?
        public var heartRate: Int
        public var timestamp: Date

        public init(uuid: UUID?, heartRate: Int, timestamp: Date) {
            self.uuid = uuid
            self.heartRate = heartRate
            self.timestamp = timestamp
        }
        
        public var asTemp: TempWorkoutHeartRateDataSample {
            return self
        }
    }
    
    public class Event: Codable, TempValueConvertible {

        public var uuid: UUID?
        public var title: String
        public var comment: String?
        public var startDate: Date?
        public var endDate: Date?
        public var workouts: [UUID]

        public init(uuid: UUID?, title: String, comment: String?, startDate: Date?, endDate: Date?, workouts: [UUID]) {
            self.uuid = uuid
            self.title = title
            self.comment = comment
            self.startDate = startDate
            self.endDate = endDate
            self.workouts = workouts
        }
        
        public var asTemp: TempEvent {
            return self
        }
    }
    
}
