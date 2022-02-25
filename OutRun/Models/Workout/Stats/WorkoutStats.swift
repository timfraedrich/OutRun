//
//  WorkoutStats.swift
//
//  OutRun
//  Copyright (C) 2021 Tim Fraedrich <timfraedrich@icloud.com>
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
import RxSwift
import RxCocoa

class WorkoutStats {
    
    let workout: ORWorkoutInterface
    
    let workoutType: Driver<Workout.WorkoutType>
    
    let hasSteps: Bool
    let hasWorkoutPauses: Bool
    let hasWorkoutEvents: Bool
    let hasRouteSamples: Bool
    let hasHeartRateData: Bool
    let hasEnergyValue: Bool
    
    // DISTANCE
    let distance: Driver<String>
    let steps: Driver<String?>
    let ascendingAltitude: Driver<String?>
    let descendingAltitude: Driver<String?>
    let altitudeOverTime: Driver<WorkoutStatsSeries<Bool, Double, WorkoutRouteDataSample>>
    
    // DURATION
    let startDate: Driver<Date>
    let endDate: Driver<Date>
    let activeDuration: Driver<String>
    let pauseDuration: Driver<String?>
    
    // SPEED
    let averageSpeed: Driver<String>
    let topSpeed: Driver<String>
    let speedOverTime: Driver<WorkoutStatsSeries<Bool, Double, WorkoutRouteDataSample>>
    
    // ENERGY
    let burnedEnergy: Driver<String?>
    var burnedEnergyPerMinute: Driver<String?>
    
    // HEART RATE
    let averageHeartRate: Driver<String?>
    let heartRateOverTime: Driver<WorkoutStatsSeries<Bool, Int, WorkoutHeartRateDataSample>>
    
    init(workout: Workout) {
        
        self.workout = workout
        
        self.workoutType = .just(workout.workoutType)
        
        self.hasSteps = workout.steps != nil
        self.hasWorkoutPauses = !workout.pauses.isEmpty
        self.hasWorkoutEvents = !workout.workoutEvents.isEmpty
        self.hasRouteSamples = !workout.routeData.isEmpty
        self.hasHeartRateData = !workout.heartRates.isEmpty
        self.hasEnergyValue = workout.burnedEnergy != nil
        
        self.distance = WorkoutStats.just(workout.distance, unit: UnitLength.standardUnit)
        self.steps = WorkoutStats.just(Double(workout.steps), unit: UnitCount.count)
        self.ascendingAltitude = WorkoutStats.just(workout.ascend, unit: UnitLength.meters, type: .altitude)
        self.descendingAltitude = WorkoutStats.just(workout.descend, unit: UnitLength.meters, type: .altitude)
        self.altitudeOverTime = WorkoutStats.series(from: workout, samples: \Workout._routeData.value, metric: \WorkoutRouteDataSample._altitude.value)
        
        self.startDate = .just(workout.startDate)
        self.endDate = .just(workout.endDate)
        self.activeDuration = WorkoutStats.just(workout.activeDuration, unit: UnitDuration.seconds)
        self.pauseDuration = WorkoutStats.just(workout.pauseDuration, unit: UnitDuration.seconds)
        
        self.averageSpeed = WorkoutStats.just(workout.distance / workout.activeDuration, unit: UnitSpeed.metersPerSecond)
        self.topSpeed = WorkoutStats.just(workout.routeData.max{ $0.speed > $1.speed }?.speed, unit: UnitSpeed.metersPerSecond)
        self.speedOverTime = WorkoutStats.series(from: workout, samples: \Workout._routeData, metric: \WorkoutRouteDataSample._speed.value)
        
        self.burnedEnergy = WorkoutStats.just(workout.burnedEnergy, unit: UnitEnergy.standardUnit)
        self.burnedEnergyPerMinute = WorkoutStats.just((workout.burnedEnergy ?? 0) / (workout.activeDuration / 60), unit: UnitPower.energyPerMinute(from: .kilocalories)) // find better solution
        
        self.averageHeartRate = WorkoutStats.just(Double(workout.heartRates.map { $0.heartRate }.reduce(0, +) / workout.heartRates.count), unit: UnitCount.count, type: .count)
        self.heartRateOverTime = WorkoutStats.series(from: workout, samples: \Workout._heartRates.value, metric: \WorkoutHeartRateDataSample._heartRate.value)
    }
    
    /**
     Creates a static observable optional string driver from the provided value, unit and formating behaviour specified.
     - parameter value: the value supposed to be formatted
     - parameter unit: the unit in which the value is provided
     - parameter type: the type by which the value is formatted, `.auto` by default
     - parameter rounding: the type by which the value is rounded, `.twoDigits` by default
     - returns: a static observable optional string driver
     */
    private static func just(
        _ value: Double?,
        unit: Unit?,
        type: CustomMeasurementFormatting.FormattingMeasurementType = .auto,
        rounding: CustomMeasurementFormatting.FormattingRoundingType = .twoDigits
    ) -> Driver<String?> {
        
        .just(StatsHelper.string(for: value, unit: unit, type: type, rounding: rounding))
    }
    
    /**
     Creates a static observable string driver from the provided value, unit and formating behaviour specified.
     - parameter value: the value supposed to be formatted
     - parameter unit: the unit in which the value is provided
     - parameter type: the type by which the value is formatted, `.auto` by default
     - parameter rounding: the type by which the value is rounded, `.twoDigits` by default
     - returns: a static observable string driver, the driver provides `"--"` if formatting fails
     */
    private static func just(
        _ value: Double?,
        unit: Unit?,
        type: CustomMeasurementFormatting.FormattingMeasurementType = .auto,
        rounding: CustomMeasurementFormatting.FormattingRoundingType = .twoDigits
    ) -> Driver<String> {
        
        just(value, unit: unit, type: type, rounding: rounding).map { $0 ?? "--" }.asDriver()
    }
    
    /**
     Queries a series of a specific metric from specified samples relative to the start date of the workout and grouped by if they are paused or not.
     - parameter workout: the workout object used to query samples from
     - parameter samples: a keypath pointing to the samples of which the matric should be taken
     - parameter metric: a keypath pointing to the metric of the before specified sample
     */
    private static func series <SampleType: Collection, MetricType: Any> (
        from workout: ORWorkoutInterface,
        samples samplesPath: KeyPath<Workout, SampleType>,
        metric metricPath: KeyPath<SampleType.Element, MetricType>
    ) -> Driver<WorkoutStatsSeries<Bool, MetricType, SampleType.Element>> where SampleType.Element: ORSampleInterface {
        
        Observable.create { observer in
            
            var disposed = false
            
            DataManager.querySectionedMetrics(
                from: workout,
                samples: samplesPath,
                metric: metricPath,
                completion: { seriesData in
                    guard !disposed else { return }
                    observer.onNext(seriesData)
                    observer.onCompleted()
                }
            )
            
            return Disposables.create {
                disposed = true
            }
            
        }.asDriver(onErrorJustReturn: [])
    }
}
