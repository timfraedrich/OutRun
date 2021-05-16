//
//  HealthWorkout.swift
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

class HealthWorkout: TempWorkout {
    
    let hkWorkout: HKWorkout
    
    init?(_ hkWorkout: HKWorkout, stepsSamples: [HKQuantitySample], route: [CLLocation], workoutEvents: [HKWorkoutEvent], heartRates: [TempWorkoutHeartRateDataSample]) {
        
        guard
            let distance = hkWorkout.totalDistance?.doubleValue(for: .meter()),
            let type = Workout.WorkoutType(hkType: hkWorkout.workoutActivityType)
        else {
            return nil
        }
        
        let isUserModified = hkWorkout.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false
        
        let elevationTouple = Computation.computeElevationData(from: route.map { $0.altitude })
        
        let pauses = HealthWorkout.pauses(from: workoutEvents, startDate: hkWorkout.startDate, endDate: hkWorkout.endDate)
        
        let durationTouple = HealthWorkout.durationTouple(from: pauses, startDate: hkWorkout.startDate, endDate: hkWorkout.endDate)
        
        self.hkWorkout = hkWorkout
        
        super.init(
            uuid: nil,
            workoutType: type,
            distance: distance,
            steps: HealthWorkout.steps(from: stepsSamples),
            startDate: hkWorkout.startDate,
            endDate: hkWorkout.endDate,
            burnedEnergy: hkWorkout.totalEnergyBurned?.doubleValue(for: .kilocalorie()),
            isRace: false,
            comment: nil,
            isUserModified: isUserModified,
            healthKitUUID: hkWorkout.uuid,
            finishedRecording: true,
            ascend: elevationTouple.ascending,
            descend: elevationTouple.descending,
            activeDuration: durationTouple.activeDuration,
            pauseDuration: durationTouple.pauseDuration,
            dayIdentifier: CustomDateFormatting.dayIdentifier(forDate: hkWorkout.startDate),
            heartRates: heartRates,
            routeData: route.map { $0.asTemp },
            pauses: pauses,
            workoutEvents: HealthWorkout.workoutEvents(from: workoutEvents)
        )
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("[HealthWorkout] Subclass 'HealthWorkout' of TempWorkout does not support protocol 'Codable'")
    }
    
    // MARK: Static
    
    static func steps(from hkSamples: [HKQuantitySample]) -> Int? {
        var steps = Int()
        for sample in hkSamples {
            steps += Int(sample.quantity.doubleValue(for: HKUnit.count()))
        }
        return steps != 0 ? steps : nil
    }
    
    static func durationTouple(from pauses: [TempWorkoutPause], startDate: Date, endDate: Date) -> Computation.DurationTouple {
        
        let pauseTouples: [Computation.RawPauseTouple] = pauses.map { (start: $0.startDate, end: $0.endDate) }
        
        return Computation.calculateDurationData(from: startDate, end: endDate, pauses: pauseTouples)
        
    }
    
    static func pauses(from workoutEvents: [HKWorkoutEvent], startDate: Date, endDate: Date) -> [TempWorkoutPause] {
        
        let events: [Computation.EventTouple] = workoutEvents.compactMap {
            guard $0.type.isPauseType else { return nil }
            return (type: $0.type.convertedRawValue, date: $0.dateInterval.start)
        }
        
        let pauseTouples = Computation.calculateAndValidatePauses(from: events, workoutStart: startDate, workoutEnd: endDate) ?? []
        
        return pauseTouples.map {
            TempWorkoutPause(
                uuid: nil,
                startDate: $0.start,
                endDate: $0.end,
                pauseType: .init(rawValue: $0.type)
            )
        }
    }
    
    static func workoutEvents(from hkWorkoutEvents: [HKWorkoutEvent]) -> [TempWorkoutEvent] {
        
        return hkWorkoutEvents.compactMap {
            guard !$0.type.isPauseType, let eventType = WorkoutEvent.WorkoutEventType(healthType: $0.type) else { return nil }
            
            return TempWorkoutEvent(
                uuid: nil,
                eventType: eventType,
                timestamp: $0.dateInterval.start
            )
        }
    }
    
}