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

public typealias TempWorkout = TempV4.Workout
extension TempWorkout: ORWorkoutInterface {
    
    convenience init(from object: ORWorkoutInterface) {
        
        self.init(
            uuid: object.uuid,
            workoutType: object.workoutType,
            distance: object.distance,
            steps: object.steps,
            startDate: object.startDate,
            endDate: object.endDate,
            burnedEnergy: object.burnedEnergy,
            isRace: object.isRace,
            comment: object.comment,
            isUserModified: object.isUserModified,
            healthKitUUID: object.healthKitUUID,
            finishedRecording: object.finishedRecording,
            ascend: object.ascend,
            descend: object.descend,
            activeDuration: object.activeDuration,
            pauseDuration: object.pauseDuration,
            dayIdentifier: object.dayIdentifier,
            heartRates: object.heartRates.map { .init(from: $0) },
            routeData: object.routeData.map { .init(from: $0) },
            pauses: object.pauses.map { .init(from: $0) },
            workoutEvents: object.workoutEvents.map { .init(from: $0) }
        )
    }
}

public typealias TempWorkoutPause = TempV4.WorkoutPause
extension TempWorkoutPause: ORWorkoutPauseInterface {
    
    convenience init(from object: ORWorkoutPauseInterface) {
        
        self.init(
            uuid: object.uuid,
            startDate: object.startDate,
            endDate: object.endDate,
            pauseType: object.pauseType
        )
    }
    
    /**
     Combining two instances of the TempWorkoutPause object into one.
     - parameter with: the `TempWorkoutPause` object to merge
     - returns: one `TempWorkoutPause` instance with the earliest start date and the latest end date of the provided and `self`
    */
    func merge(with anotherPause: TempWorkoutPause) -> TempWorkoutPause {
        
        let commonStart = startDate < anotherPause.startDate ? startDate : anotherPause.startDate
        let commonEnd = endDate > anotherPause.endDate ? endDate : anotherPause.endDate
        
        return TempWorkoutPause(
            uuid: nil,
            startDate: commonStart,
            endDate: commonEnd,
            pauseType: [pauseType, anotherPause.pauseType].contains(.manual) ? .manual : .automatic
        )
    }
}

public typealias TempWorkoutEvent = TempV4.WorkoutEvent
extension TempWorkoutEvent: ORWorkoutEventInterface {
    
    convenience init(from object: ORWorkoutEventInterface) {
        
        self.init(
            uuid: object.uuid,
            eventType: object.eventType,
            timestamp: object.timestamp
        )
    }
}

public typealias TempWorkoutRouteDataSample = TempV4.WorkoutRouteDataSample
extension TempWorkoutRouteDataSample: ORWorkoutRouteDataSampleInterface {
    
    convenience init(from object: ORWorkoutRouteDataSampleInterface) {
        
        self.init(
            uuid: object.uuid,
            timestamp: object.timestamp,
            latitude: object.latitude,
            longitude: object.longitude,
            altitude: object.altitude,
            horizontalAccuracy: object.horizontalAccuracy,
            verticalAccuracy: object.verticalAccuracy,
            speed: object.speed,
            direction: object.direction
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

public typealias TempWorkoutHeartRateDataSample = TempV4.WorkoutHeartRateDataSample
extension TempWorkoutHeartRateDataSample: ORWorkoutHeartRateDataSampleInterface {
    
    convenience init(from object: ORWorkoutHeartRateDataSampleInterface) {
        
        self.init(
            uuid: object.uuid,
            heartRate: object.heartRate,
            timestamp: object.timestamp
        )
        
    }
    
}

public typealias TempEvent = TempV4.Event
extension TempEvent: OREventInterface {
    
    convenience init(from object: OREventInterface) {
        
        self.init(
            uuid: object.uuid,
            title: object.title,
            comment: object.comment,
            startDate: object.startDate,
            endDate: object.endDate,
            workouts: object.workouts.compactMap { $0.uuid }
        )
    }
    
}
