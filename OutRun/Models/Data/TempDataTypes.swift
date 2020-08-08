//
//  TempDataTypes.swift
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

typealias TempWorkout = TempV3.Workout
typealias TempWorkoutEvent = TempV3.WorkoutEvent
typealias TempWorkoutRouteDataSample = TempV3.WorkoutRouteDataSample
typealias TempWorkoutHeartRateDataSample = TempV3.WorkoutHeartRateDataSample
typealias TempEvent = TempV3.Event

enum TempV1 {
    
    struct Workout: Codable {
        let uuid: UUID?
        let workoutType: Int
        let startDate: Date
        let endDate: Date
        let distance: Double
        let burnedEnergy: Double
        let healthKitUUID: UUID?
        let locations: [TempV1.RouteDataSample]
    }
    
    struct RouteDataSample: Codable {
        let uuid: UUID?
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let speed: Double
        let direction: Double
    }
    
}

enum TempV2 {
    
    struct Workout: Codable {
        let uuid: UUID?
        let workoutType: Int
        let startDate: Date
        let endDate: Date
        let distance: Double
        let isRace: Bool
        let isUserModified: Bool
        let comment: String?
        let burnedEnergy: Double
        let healthKitUUID: UUID?
        let locations: [TempV2.RouteDataSample]
    }
    
    struct RouteDataSample: Codable {
        let uuid: UUID?
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let horizontalAccuracy: Double
        let verticalAccuracy: Double
        let speed: Double
        let direction: Double
    }
    
}

enum TempV3 {
    
    struct Workout: Codable {
        let uuid: UUID?
        let workoutType: Int
        let startDate: Date
        let endDate: Date
        let distance: Double
        let steps: Int?
        let isRace: Bool
        let isUserModified: Bool
        let comment: String?
        let burnedEnergy: Double?
        let healthKitUUID: UUID?
        let workoutEvents: [TempV3.WorkoutEvent]
        let locations: [TempV3.WorkoutRouteDataSample]
        let heartRates: [TempV3.WorkoutHeartRateDataSample]
    }
    
    struct WorkoutEvent: Codable {
        let uuid: UUID?
        let eventType: Int
        let startDate: Date
        let endDate: Date
    }
    
    struct WorkoutRouteDataSample: Codable {
        let uuid: UUID?
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let horizontalAccuracy: Double
        let verticalAccuracy: Double
        let speed: Double
        let direction: Double
    }
    
    struct WorkoutHeartRateDataSample: Codable {
        let uuid: UUID?
        let heartRate: Double
        let timestamp: Date
    }
    
    struct Event: Codable {
        let uuid: UUID?
        let title: String
        let comment: String?
        let startDate: Date?
        let endDate: Date?
        let workouts: [UUID]
    }
    
}

extension TempWorkout {
    
    init(workout: Workout) {
        self.init(
            uuid: workout.uuid.value,
            workoutType: workout.workoutType.value,
            startDate: workout.startDate.value,
            endDate: workout.endDate.value,
            distance: workout.distance.value,
            steps: workout.steps.value,
            isRace: workout.isRace.value,
            isUserModified: workout.isUserModified.value,
            comment: workout.comment.value,
            burnedEnergy: workout.burnedEnergy.value,
            healthKitUUID: workout.healthKitUUID.value,
            workoutEvents: workout.workoutEvents.map({ (workoutEvent) -> TempWorkoutEvent in
                return TempWorkoutEvent(workoutEvent: workoutEvent)
            }),
            locations: workout.routeData.map({ (sample) -> TempWorkoutRouteDataSample in
                return TempWorkoutRouteDataSample(routeSample: sample)
            }),
            heartRates: workout.heartRates.map({ (sample) -> TempWorkoutHeartRateDataSample in
                return TempWorkoutHeartRateDataSample(heartRateSample: sample)
            })
        )
    }
    
    init(fromV1 v1Workout: TempV1.Workout) {
        self.init(
            uuid: v1Workout.uuid,
            workoutType: v1Workout.workoutType,
            startDate: v1Workout.startDate,
            endDate: v1Workout.endDate,
            distance: v1Workout.distance,
            steps: nil,
            isRace: false,
            isUserModified: false,
            comment: nil,
            burnedEnergy: v1Workout.burnedEnergy != 0 ? v1Workout.burnedEnergy : nil,
            healthKitUUID: v1Workout.healthKitUUID,
            workoutEvents: [],
            locations: v1Workout.locations.map({ (oldSample) -> TempWorkoutRouteDataSample in
                TempWorkoutRouteDataSample(fromV1: oldSample)
            }),
            heartRates: []
        )
    }
    
    init(fromV2 v2Workout: TempV2.Workout) {
        self.init(
            uuid: v2Workout.uuid,
            workoutType: v2Workout.workoutType,
            startDate: v2Workout.startDate,
            endDate: v2Workout.endDate,
            distance: v2Workout.distance,
            steps: nil,
            isRace: v2Workout.isRace,
            isUserModified: v2Workout.isUserModified,
            comment: v2Workout.comment,
            burnedEnergy: v2Workout.burnedEnergy != 0 ? v2Workout.burnedEnergy : nil,
            healthKitUUID: v2Workout.healthKitUUID,
            workoutEvents: [],
            locations: v2Workout.locations.map({ (oldSample) -> TempWorkoutRouteDataSample in
                TempWorkoutRouteDataSample(fromV2: oldSample)
            }),
            heartRates: []
        )
    }
    
    var realWorkoutType: Workout.WorkoutType {
        return Workout.WorkoutType(rawValue: self.workoutType)
    }
    
}

extension TempWorkoutEvent {
    
    init(workoutEvent: WorkoutEvent) {
        self.init(
            uuid: workoutEvent.uuid.value,
            eventType: workoutEvent.eventType.value,
            startDate: workoutEvent.startDate.value,
            endDate: workoutEvent.endDate.value
        )
    }
    
    init(type: WorkoutEvent.WorkoutEventType, startDate: Date, endDate: Date) {
        self.init(
            uuid: nil,
            eventType: type.rawValue,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    init(type: WorkoutEvent.WorkoutEventType, date: Date) {
        self.init(
            type: type,
            startDate: date,
            endDate: date
        )
    }
    
    init(healthEvent: HKWorkoutEvent) {
        self.init(
            uuid: nil,
            eventType: WorkoutEvent.WorkoutEventType(healthType: healthEvent.type).rawValue,
            startDate: healthEvent.dateInterval.start,
            endDate: healthEvent.dateInterval.end
        )
    }
    
    var realEventType: WorkoutEvent.WorkoutEventType {
        WorkoutEvent.WorkoutEventType(rawValue: self.eventType)
    }
    
}

extension TempWorkoutRouteDataSample: TempWorkoutSeriesDataSampleType {
    
    init?<T>(sample: T) where T : WorkoutSeriesDataSampleType {
        if let sample = sample as? WorkoutRouteDataSample {
            self.init(routeSample: sample)
        } else {
            return nil
        }
    }
    
    init(routeSample: WorkoutRouteDataSample) {
        self.init(
            uuid: routeSample.uuid.value,
            timestamp: routeSample.timestamp.value,
            latitude: routeSample.latitude.value,
            longitude: routeSample.longitude.value,
            altitude: routeSample.altitude.value,
            horizontalAccuracy: routeSample.horizontalAccuracy.value,
            verticalAccuracy: routeSample.verticalAccuracy.value,
            speed: routeSample.speed.value,
            direction: routeSample.direction.value
        )
    }
    
    init(clLocation: CLLocation) {
        self.init(
            uuid: nil,
            timestamp: clLocation.timestamp,
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude,
            altitude: clLocation.altitude,
            horizontalAccuracy: clLocation.horizontalAccuracy,
            verticalAccuracy: clLocation.verticalAccuracy,
            speed: clLocation.speed,
            direction: clLocation.course
        )
    }
    
    init(fromV1 v1Sample: TempV1.RouteDataSample) {
        self.init(
            uuid: v1Sample.uuid,
            timestamp: v1Sample.timestamp,
            latitude: v1Sample.latitude,
            longitude: v1Sample.longitude,
            altitude: v1Sample.altitude,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            speed: v1Sample.speed,
            direction: v1Sample.direction
        )
    }
    
    init(fromV2 v2Sample: TempV2.RouteDataSample) {
        self.init(
            uuid: v2Sample.uuid,
            timestamp: v2Sample.timestamp,
            latitude: v2Sample.latitude,
            longitude: v2Sample.longitude,
            altitude: v2Sample.altitude,
            horizontalAccuracy: v2Sample.horizontalAccuracy,
            verticalAccuracy: v2Sample.verticalAccuracy,
            speed: v2Sample.speed,
            direction: v2Sample.direction
        )
    }
    
    var clLocation: CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude),
            altitude: self.altitude,
            horizontalAccuracy: self.horizontalAccuracy,
            verticalAccuracy: self.verticalAccuracy,
            course: self.direction,
            speed: self.speed,
            timestamp: self.timestamp
        )
    }
    
}

extension TempWorkoutHeartRateDataSample: TempWorkoutSeriesDataSampleType {
    
    init?<T>(sample: T) where T : WorkoutSeriesDataSampleType {
        if let sample = sample as? WorkoutHeartRateDataSample {
            self.init(heartRateSample: sample)
        } else {
            return nil
        }
    }
    
    init(heartRateSample: WorkoutHeartRateDataSample) {
        self.init(
            uuid: heartRateSample.uuid.value,
            heartRate: heartRateSample.heartRate.value,
            timestamp: heartRateSample.timestamp.value
        )
    }
    
}

extension TempEvent {
    
    init(event: Event) {
        self.init(
            uuid: event.uuid.value,
            title: event.title.value,
            comment: event.comment.value,
            startDate: event.startDate.value,
            endDate: event.endDate.value,
            workouts: event.workouts.compactMap({ (workout) -> UUID? in
                return workout.uuid.value
            })
        )
    }
    
}
