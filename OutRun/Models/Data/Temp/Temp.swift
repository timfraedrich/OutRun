//
//  Temp.swift
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
import HealthKit

typealias TempWorkout = TempV4.Workout
extension TempWorkout: ORWorkoutInterface {
    
    convenience init<Type: TempValueConvertible>(from object: Type) where Type.TempType == TempWorkout {
        
        let temp = object.asTemp
        
        self.init(
            uuid: temp.uuid,
            workoutType: temp.workoutType,
            distance: temp.distance,
            steps: temp.steps,
            startDate: temp.startDate,
            endDate: temp.endDate,
            burnedEnergy: temp.burnedEnergy,
            isRace: temp.isRace,
            comment: temp.comment,
            isUserModified: temp.isUserModified,
            healthKitUUID: temp.healthKitUUID,
            finishedRecording: temp.finishedRecording,
            ascend: temp.ascend,
            descend: temp.descend,
            activeDuration: temp.activeDuration,
            pauseDuration: temp.pauseDuration,
            dayIdentifier: temp.dayIdentifier,
            heartRates: temp.heartRates,
            routeData: temp.routeData,
            pauses: temp.pauses,
            workoutEvents: temp.workoutEvents
        )
    }
}

typealias TempWorkoutPause = TempV4.WorkoutPause
extension TempWorkoutPause: ORWorkoutPauseInterface {
    
    convenience init<Type: TempValueConvertible>(from object: Type) where Type.TempType == TempWorkoutPause {
        
        let temp = object.asTemp
        
        self.init(
            uuid: temp.uuid,
            startDate: temp.startDate,
            endDate: temp.endDate,
            pauseType: temp.pauseType
        )
    }
}

typealias TempWorkoutEvent = TempV4.WorkoutEvent
extension TempWorkoutEvent: ORWorkoutEventInterface {
    
    convenience init<Type: TempValueConvertible>(from object: Type) where Type.TempType == TempWorkoutEvent {
        
        let temp = object.asTemp
        
        self.init(
            uuid: temp.uuid,
            eventType: temp.eventType,
            timestamp: temp.timestamp
        )
    }
}

typealias TempWorkoutRouteDataSample = TempV4.WorkoutRouteDataSample
extension TempWorkoutRouteDataSample: ORWorkoutRouteDataSampleInterface {
    
    convenience init<Type: TempValueConvertible>(from object: Type) where Type.TempType == TempWorkoutRouteDataSample {
        
        let temp = object.asTemp
        
        self.init(
            uuid: temp.uuid,
            timestamp: temp.timestamp,
            latitude: temp.latitude,
            longitude: temp.longitude,
            altitude: temp.altitude,
            horizontalAccuracy: temp.horizontalAccuracy,
            verticalAccuracy: temp.verticalAccuracy,
            speed: temp.speed,
            direction: temp.direction
        )
    }
    
    var clLocation: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: self.latitude,
                longitude: self.longitude
            ),
            altitude: self.altitude,
            horizontalAccuracy: self.horizontalAccuracy,
            verticalAccuracy: self.verticalAccuracy,
            course: self.direction,
            speed: self.speed,
            timestamp: self.timestamp
        )
    }
    
}

typealias TempWorkoutHeartRateDataSample = TempV4.WorkoutHeartRateDataSample
extension TempWorkoutHeartRateDataSample: ORWorkoutHeartRateDataSampleInterface {
    
    convenience init<Type: TempValueConvertible>(from object: Type) where Type.TempType == TempWorkoutHeartRateDataSample {
        
        let temp = object.asTemp
        
        self.init(
            uuid: temp.uuid,
            heartRate: temp.heartRate,
            timestamp: temp.timestamp
        )
        
    }
    
}

typealias TempEvent = TempV4.Event
extension TempEvent: OREventInterface {
    
    convenience init<Type: TempValueConvertible>(from object: Type) where Type.TempType == TempEvent {
        
        let temp = object.asTemp
        
        self.init(
            uuid: temp.uuid,
            title: temp.title,
            comment: temp.comment,
            startDate: temp.startDate,
            endDate: temp.endDate,
            workouts: temp.workouts
        )
    }
    
}
