//
//  LiveStats.swift
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
import RxSwift
import RxCocoa
import CoreLocation

class LiveStats: WorkoutBuilderComponent, ReactiveCompatible {
    
    // MARK: - Dataflow
    
    /// The `DisposeBag` used for binding to the workout builder.
    private var disposeBag = DisposeBag()
    
    /// The relay to publish the current status of the `WorkoutBuilder`.
    fileprivate let statusRelay = BehaviorRelay<WorkoutBuilder.Status>(value: .waiting)
    /// The relay to publish the type of workout the `WorkoutBuilder` is supposed to record.
    fileprivate let workoutTypeRelay = BehaviorRelay<Workout.WorkoutType?>(value: nil)
    /// The relay to publish the distance shared by components.
    fileprivate let distanceRelay = BehaviorRelay<String>(value: StatsHelper.string(for: 0, unit: UserPreferences.distanceMeasurementType.safeValue))
    /// The relay to publish the steps counted by components.
    fileprivate let stepsRelay = BehaviorRelay<String>(value: StatsHelper.string(for: 0, unit: UnitCount.count))
    /// The relay to publish the current location regardless of whether it was recorded or not.
    fileprivate let currentLocationRelay = BehaviorRelay<TempWorkoutRouteDataSample?>(value: nil)
    /// The relay to publish the recorded locations received from components.
    fileprivate let locationsRelay = BehaviorRelay<[TempWorkoutRouteDataSample]>(value: [])
    /// The relay to publish the heart rate samples received from components.
    fileprivate let currentHeartRateRelay = BehaviorRelay<TempWorkoutHeartRateDataSample?>(value: nil)
    /// The relay to publish a components report of isufficient permissions to record the workout.
    fileprivate let insufficientPermissionRelay = PublishRelay<String>()
    
    /// The relay to publish a string describing the elapsed duration of the workout.
    fileprivate let durationRelay = BehaviorRelay<String>(value: StatsHelper.string(for: 0, unit: UnitDuration.seconds, type: .clock))
    /// The relay to publish the energy burned during the workout as computed periodically.
    fileprivate let burnedEnergyRelay = BehaviorRelay<String>(value: StatsHelper.string(for: 0, unit: UserPreferences.energyMeasurementType.safeValue))
    /// The relay to publish the speed returned in meters per second.
    fileprivate let speedRelay = BehaviorRelay<String>(value: StatsHelper.string(for: 0, unit: UserPreferences.speedMeasurementType.safeValue, type: (UserPreferences.speedMeasurementType.safeValue == UnitSpeed.minutesPerLengthUnit(from: UnitLength.standardBigLocalUnit as! UnitLength)) ? .pace : .auto))
    
    // MARK: Binders
    
    /// Maps distance updates to a desired output.
    private var distanceMapper: (Double) -> String = { distance in
        return StatsHelper.string(for: distance, unit: UnitLength.standardUnit)
    }
    
    /// Maps distance updates to a desired output.
    private var stepsMapper: (Int?) -> String = { steps in
        return StatsHelper.string(for: Double(steps), unit: UnitCount.count)
    }
    
    /// Maps to duration output.
    private var durationMapper: (((Int, Date?), [TempWorkoutPause]), Date?) -> String? = { value, endDate in
        let ((_, startDate), pauses) = value
        guard let startDate = startDate else { return nil }
        let duration = startDate.distance(to: endDate ?? Date()) - pauses.map { $0.duration }.reduce(0, +)
        return StatsHelper.string(for: duration, unit: UnitDuration.seconds, type: .clock)
    }
    
    /// Maps to burned energy output.
    private var burnedEnergyMapper: ((Int, Workout.WorkoutType), Double) -> String? = { value, distance in
        let workoutType = value.1
        guard let weight = UserPreferences.weight.value else { return nil }
        let burnedEnergy = Computation.calculateBurnedEnergy(for: workoutType, distance: distance, weight: weight)
        return StatsHelper.string(for: burnedEnergy, unit: UnitEnergy.standardUnit)
    }
    
    /// Binds location updates and the current start date to this component for speed calculation
    private var speedMapper: ((([TempWorkoutRouteDataSample], Date?), [TempWorkoutPause]), Double) -> String? = { value, distance in
        let ((locations, startDate), pauses) = value
        guard let startDate = startDate else { return nil }
        
        let speed: Double?
        
        if UserPreferences.displayRollingSpeed.value { // rolling
            
            var (tempDistance, tempDuration, lastLocation): (Double, Double, CLLocation?) = (0, 0, nil)
            
            for location in locations.reversed() where tempDistance < 1000 {
                guard !pauses.contains(where: { $0.contains(location.timestamp) }) else {
                    lastLocation = nil
                    continue
                }
                
                if let lastLocation = lastLocation {
                    tempDistance += location.clLocation.distance(from: lastLocation)
                    tempDuration += location.timestamp.distance(to: lastLocation.timestamp)
                }
                lastLocation = location.clLocation
            }
            
            guard tempDuration > 0, tempDistance > 0 else { return nil }
            speed = tempDistance / tempDuration
            
        } else { // average
            
            let duration = startDate.distance(to: Date()) - pauses.map { $0.duration }.reduce(0, +)
            speed = distance / duration
        }
        
        return StatsHelper.string(for: speed, unit: UnitSpeed.standardUnit)
    }
    
    // MARK: WorkoutBuilderComponent
    
    public required init(builder: WorkoutBuilder) {
        self.bind(builder: builder)
    }
    
    func bind(builder: WorkoutBuilder) {
        
        disposeBag = DisposeBag()
        
        let output = builder.tranform(Input())
            
        output.status
            .pausableBuffered(output.isUISuspended)
            .bind(to: statusRelay)
            .disposed(by: disposeBag)
        
        output.workoutType
            .pausableBuffered(output.isUISuspended)
            .bind(to: workoutTypeRelay)
            .disposed(by: disposeBag)
        
        output.distance
            .map(distanceMapper)
            .pausableBuffered(output.isUISuspended)
            .bind(to: distanceRelay)
            .disposed(by: disposeBag)
        
        output.steps
            .map(stepsMapper)
            .pausableBuffered(output.isUISuspended)
            .bind(to: stepsRelay)
            .disposed(by: disposeBag)
        
        output.currentLocation
            .pausableBuffered(output.isUISuspended)
            .bind(to: currentLocationRelay)
            .disposed(by: disposeBag)
        
        output.locations
            .pausableBuffered(output.isUISuspended)
            .bind(to: locationsRelay)
            .disposed(by: disposeBag)
        
        output.heartRates
            .compactMap { $0.last }
            .pausableBuffered(output.isUISuspended)
            .bind(to: currentHeartRateRelay)
            .disposed(by: disposeBag)
        
        output.insufficientPermission
            .pausableBuffered(output.isUISuspended, limit: nil)
            .bind(to: insufficientPermissionRelay)
            .disposed(by: disposeBag)
        
        let periodicUpdates = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.asyncInstance)
        
        periodicUpdates
            .combineWithLatestFrom(output.startDate)
            .combineWithLatestFrom(output.pauses)
            .combineWithLatestFrom(output.endDate)
            .compactMap(durationMapper)
            .pausableBuffered(output.isUISuspended)
            .bind(to: durationRelay)
            .disposed(by: disposeBag)
        
        periodicUpdates
            .combineWithLatestFrom(output.workoutType)
            .combineWithLatestFrom(output.distance)
            .compactMap(burnedEnergyMapper)
            .pausableBuffered(output.isUISuspended)
            .bind(to: burnedEnergyRelay)
            .disposed(by: disposeBag)
        
        output.locations
            .combineWithLatestFrom(output.startDate)
            .combineWithLatestFrom(output.pauses)
            .combineWithLatestFrom(output.distance)
            .compactMap(speedMapper)
            .pausableBuffered(output.isUISuspended)
            .bind(to: speedRelay)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Reactive
    
    var status: Driver<WorkoutBuilder.Status> { self.statusRelay.asDriver() }
    var workoutType: Driver<Workout.WorkoutType?> { self.workoutTypeRelay.asDriver() }
    var distance: Driver<String> { self.distanceRelay.asDriver() }
    var steps: Driver<String> { self.stepsRelay.asDriver() }
    var currentLocation: Driver<TempWorkoutRouteDataSample?> { self.currentLocationRelay.asDriver() }
    var locations: Driver<[TempWorkoutRouteDataSample]> { self.locationsRelay.asDriver() }
    var currentHeartRate: Driver<TempWorkoutHeartRateDataSample?> { self.currentHeartRateRelay.asDriver() }
    var insufficientPermission: Driver<String> { self.insufficientPermissionRelay.asDriver(onErrorJustReturn: "Error") }
    var duration: Driver<String> { self.durationRelay.asDriver() }
    var burnedEnergy: Driver<String> { self.burnedEnergyRelay.asDriver() }
    var speed: Driver<String> { self.speedRelay.asDriver() }
}
