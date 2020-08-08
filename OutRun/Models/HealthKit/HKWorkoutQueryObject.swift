//
//  HKWorkoutQueryObject.swift
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
import CoreLocation
import UIKit

class HKWorkoutQueryObject: CustomStringConvertible {
    
    var description: String {
        return "HKWorkoutQueryObject(uuid: \(hkWorkout.uuid)"
    }
    
    let hkWorkout: HKWorkout
    
    let type: Workout.WorkoutType
    let startDate: Date
    let endDate: Date
    let distance: NSMeasurement
    var steps: Int?
    let energyBurned: NSMeasurement?
    let duration: NSMeasurement
    let isUserEntered: Bool
    
    var events: [TempWorkoutEvent] = []
    var locations: [TempWorkoutRouteDataSample] = []
    var heartRates: [TempWorkoutHeartRateDataSample] = []
    
    init?(_ workout: HKWorkout) {
        
        guard workout.totalDistance != nil else {
            return nil
        }
        
        self.hkWorkout = workout
        
        self.isUserEntered = hkWorkout.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
        
        guard let type = Workout.WorkoutType(hkType: workout.workoutActivityType) else {
            return nil
        }
        
        self.type = type
        
        self.startDate = workout.startDate
        self.endDate = workout.endDate
        
        self.duration = NSMeasurement(doubleValue: endDate.distance(to: startDate), unit: UnitDuration.seconds)
        self.distance = NSMeasurement(doubleValue: workout.totalDistance!.doubleValue(for: .meter()), unit: UnitLength.meters)
        
        if let energyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
            let energyMeasurement = NSMeasurement(doubleValue: energyBurned, unit: UnitEnergy.kilocalories)
            self.energyBurned = energyMeasurement
        } else {
            self.energyBurned = nil
        }
        
        if let workoutEvents = workout.workoutEvents?.map({ (event) -> TempWorkoutEvent in
            return TempWorkoutEvent(healthEvent: event)
        }) {
            self.events = workoutEvents
        }
    }
}
