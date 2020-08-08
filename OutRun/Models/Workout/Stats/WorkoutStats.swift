//
//  WorkoutStats.swift
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

class WorkoutStats {
    
    // GENERAL
    /// related workout reference: DON'T ACCESS, ONLY PASS ON TO THREAD SAFE MANAGERS
    let workout: Workout
    
    let type: Workout.WorkoutType
    
    let hasWorkoutEvents: Bool
    let hasRouteSamples: Bool
    let hasHeartRateData: Bool
    let hasEnergyValue: Bool
    
    // DISTANCE
    let distance: NSMeasurement
    let steps: NSMeasurement?
    let ascendingAltitude: NSMeasurement?
    let descendingAltitude: NSMeasurement?
    
    // DURATION
    let startDate: Date
    let endDate: Date
    let activeDuration: NSMeasurement
    let pauseDuration: NSMeasurement
    var pace: RelativeMeasurement {
        RelativeMeasurement(
            primary: activeDuration.converting(to: UnitDuration.minutes),
            dividing: distance.converting(to: UserPreferences.distanceMeasurementType.safeValue)
        )
    }
    
    // SPEED
    let averageSpeed: NSMeasurement
    let topSpeed: NSMeasurement?
    
    // ENERGY
    let burnedEnergy: NSMeasurement?
    var timeRelativeBurnedEnergy: RelativeMeasurement? {
        guard let burnedEnergy = burnedEnergy else {
            return nil
        }
        let time = activeDuration.converting(to: UnitDuration.minutes)
        let energy = burnedEnergy.converting(to: UserPreferences.energyMeasurementType.safeValue)
        return RelativeMeasurement(primary: energy, dividing: time)
    }
    
    init(workout: Workout) {
        
        self.workout = workout
        
        self.type = workout.type
        
        self.hasWorkoutEvents = !workout.workoutEvents.isEmpty
        self.hasRouteSamples = !workout.routeData.isEmpty
        self.hasHeartRateData = !workout.heartRates.isEmpty
        self.hasEnergyValue = workout.burnedEnergy.value != nil
        
        self.distance = NSMeasurement(doubleValue: workout.distance.value, unit: UnitLength.meters)
        self.steps = workout.steps.value != nil ? NSMeasurement(doubleValue: Double(workout.steps.value!), unit: UnitCount.count) : nil
        
        self.startDate = workout.startDate.value
        self.endDate = workout.endDate.value
        self.activeDuration = NSMeasurement(doubleValue: workout.activeDuration.value, unit: UnitDuration.seconds)
        self.pauseDuration = NSMeasurement(doubleValue: workout.pauseDuration.value, unit: UnitDuration.seconds)
        
        self.averageSpeed = NSMeasurement(doubleValue: activeDuration.doubleValue != 0 ? (distance.doubleValue / activeDuration.doubleValue) : 0, unit: UnitSpeed.metersPerSecond)
        
        self.burnedEnergy = hasEnergyValue ? NSMeasurement(doubleValue: workout.burnedEnergy.value ?? 0, unit: UnitEnergy.kilocalories) : nil
        
        if hasRouteSamples {
            
            self.ascendingAltitude = NSMeasurement(doubleValue: workout.ascendingAltitude.value, unit: UnitLength.meters)
            self.descendingAltitude = NSMeasurement(doubleValue: workout.descendingAltitude.value, unit: UnitLength.meters)
            
            self.topSpeed = {
                if let speed = (workout.routeData.max { (first, second) -> Bool in
                    return first.speed.value < second.speed.value
                })?.speed.value {
                    return NSMeasurement(doubleValue: speed, unit: UnitSpeed.metersPerSecond)
                } else {
                    return nil
                }
            }()
        } else {
            
            self.ascendingAltitude = nil
            self.descendingAltitude = nil
            self.topSpeed = nil
            
        }
        
    }
    
    var lastQueriedAltitudeSeries: (Bool, WorkoutStatsSeries?)?
    func queryAltitudes(completion: @escaping (Bool, WorkoutStatsSeries?) -> Void) {
        DispatchQueue.main.async {
            if let last = self.lastQueriedAltitudeSeries {
                completion(last.0, last.1)
                return
            }
            
            DataQueryManager.queryStatsSeries(
                for: self.workout,
                sampleType: WorkoutRouteDataSample.self,
                dataPoint: { (workout, routeSample) -> (time: TimeInterval, value: Double, unit: Unit) in
                    let time = workout.startDate.value.distance(to: routeSample.timestamp.value)
                    let value = routeSample.altitude.value
                    let unit = UnitLength.meters
                    return (time: time, value: value, unit: unit)
                },
                completion: { (success, series) in
                    self.lastQueriedAltitudeSeries = (success, series)
                    completion(success, series)
                }
            )
        }
    }
    
    var lastQueriedSpeedSeries: (Bool, WorkoutStatsSeries?)?
    func querySpeeds(completion: @escaping (Bool, WorkoutStatsSeries?) -> Void) {
        DispatchQueue.main.async {
            if let last = self.lastQueriedSpeedSeries {
                completion(last.0, last.1)
                return
            }
            DataQueryManager.queryStatsSeries(
                for: self.workout,
                sampleType: WorkoutRouteDataSample.self,
                dataPoint: { (workout, routeSample) -> (time: TimeInterval, value: Double, unit: Unit) in
                    let time = workout.startDate.value.distance(to: routeSample.timestamp.value)
                    let value = routeSample.speed.value
                    let unit = UnitSpeed.metersPerSecond
                    return (time: time, value: value, unit: unit)
                },
                completion: { (success, series) in
                    self.lastQueriedSpeedSeries = (success, series)
                    completion(success, series)
                }
            )
        }
    }
    
    var lastQueriedHeartRateSeries: (Bool, WorkoutStatsSeries?)?
    func queryHeartRates(completion: @escaping (Bool, WorkoutStatsSeries?) -> Void) {
        DispatchQueue.main.async {
            if let last = self.lastQueriedHeartRateSeries {
                completion(last.0, last.1)
                return
            }
            DataQueryManager.queryStatsSeries(
                for: self.workout,
                sampleType: WorkoutHeartRateDataSample.self,
                dataPoint: { (workout, routeSample) -> (time: TimeInterval, value: Double, unit: Unit) in
                    let time = workout.startDate.value.distance(to: routeSample.timestamp.value)
                    let value = routeSample.heartRate.value
                    let unit = UnitCount.count
                    return (time: time, value: value, unit: unit)
                },
                completion: { (success, series) in
                    self.lastQueriedHeartRateSeries = (success, series)
                    completion(success, series)
                }
            )
        }
    }
}
