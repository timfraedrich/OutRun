//
//  WorkoutBuilder.swift
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
import RxSwift
import RxRelay

public class WorkoutBuilder: ApplicationStateObserver {
    
    /// Indicating the type and last time when a workout was paused by the user or the app.
    private var lastPause: (type: WorkoutPause.WorkoutPauseType, startingAt: Date)?
    /// Holds a reference to the types of workout builder components still preparing to record.
    private var preparingComponents: [WorkoutBuilderComponent.Type] = []
    
    // MARK: - Initialisation
    
    /**
     Initialises a `WorkoutBuilder` instance.
     - parameter workoutType: an optional of the type of workout that is supposed to be recorded; if `nil` the `WorkoutBuilder` sets it appropriately from `UserPreferences.standardWorkoutType`
     - parameter delegate: the delegate that is supposed to receive updates
     */
    public init(workoutType: Workout.WorkoutType? = nil) {
        
        self.workoutTypeRelay = BehaviorRelay(value: workoutType ?? Workout.WorkoutType(rawValue: UserPreferences.standardWorkoutType.value))
        
        self.startObservingApplicationState()
    }
    
    // MARK: - Bindings
    
    private func prepareBindings() {
        
        // reacting to status changes
        statusRelay.subscribe(onNext: { [weak self] newStatus in
            guard let self = self else { return }
            let timestamp = Date()
            
            switch newStatus {
            case .recording: // starting / resuming workout
                if self.startDateRelay.value == nil {
                    self.startDateRelay.accept(timestamp)
                    
                } else if let lastPause = self.lastPause {
                    self.lastPause = nil
                    if lastPause.type == .automatic, lastPause.startingAt.distance(to: timestamp) < 3 {
                        return // to eliminate short auto pauses
                    }
                    let pause = TempWorkoutPause(uuid: nil, startDate: lastPause.startingAt, endDate: timestamp, pauseType: lastPause.type)
                    let pauses = self.pausesRelay.value + [pause]
                    self.pausesRelay.accept(pauses)
                }
            
            case .paused, .autoPaused: // (auto) pausing workout
                let pauseType = newStatus == .paused ? WorkoutPause.WorkoutPauseType.manual : .automatic
                if let lastPauseObject = self.pausesRelay.value.last, lastPauseObject.pauseType == pauseType, lastPauseObject.endDate.distance(to: timestamp) < 3 {
                    // last pause is of same type and under three seconds in the past -> merge
                    self.lastPause = (type: pauseType, startingAt: lastPauseObject.startDate)
                } else {
                    // normal pause will be created
                    self.lastPause = (type: pauseType, startingAt: self.lastPause?.startingAt ?? timestamp)
                }
                
            case .ready: // stopping workout or indicating readiness
                guard self.startDateRelay.value != nil else { return }
                
                if let lastPause = self.lastPause {
                    let pause = TempWorkoutPause(uuid: nil, startDate: lastPause.startingAt, endDate: timestamp, pauseType: lastPause.type)
                    let pauses = self.pausesRelay.value + [pause]
                    self.pausesRelay.accept(pauses)
                }
                
                self.endDateRelay.accept(timestamp)
                
                // ========================================================
                // TODO: handle finished workout ==========================
                // ========================================================
                
                self.reset()
                
            default: // ignore everything else
                break
            }
        }).disposed(by: disposeBag)
        
    }
    
    // MARK: - Dataflow
    
    /// The `DisposeBag` used for links to components and own permanent subscriptions.
    private let disposeBag = DisposeBag()
    
    /// The relay to publish the current status of the `WorkoutBuilder`.
    private let statusRelay = BehaviorRelay<WorkoutBuilder.Status>(value: .waiting)
    /// The relay to publish the type of workout the `WorkoutBuilder` is supposed to record.
    private let workoutTypeRelay: BehaviorRelay<Workout.WorkoutType>
    /// The relay to publish the date the recorded workout was started.
    private let startDateRelay = BehaviorRelay<Date?>(value: nil)
    /// The relay to publish the date the recorded workout was stopped.
    private let endDateRelay = BehaviorRelay<Date?>(value: nil)
    /// The relay to publish the distance shared by components.
    private let distanceRelay = BehaviorRelay<Double>(value: 0)
    /// The relay to publish the steps counted by components.
    private let stepsRelay = BehaviorRelay<Int?>(value: nil)
    /// The relay to publish the pauses initiated by the user or by the app automaticallyprivate
    private let pausesRelay = BehaviorRelay<[TempWorkoutPause]>(value: [])
    /// The relay to publish the current location regardless of whether it was recorded or not.
    private let currentLocationRelay = BehaviorRelay<TempWorkoutRouteDataSample?>(value: nil)
    /// The relay to publish the recorded locations received from components.
    private let locationsRelay = BehaviorRelay<[TempWorkoutRouteDataSample]>(value: [])
    /// The relay to publish the altitudes received from components.
    private let altitudesRelay = BehaviorRelay<[AltitudeManagement.AltitudeSample]>(value: [])
    /// The relay to publish the heart rate samples received from components.
    private let heartRatesRelay = BehaviorRelay<[TempWorkoutHeartRateDataSample]>(value: [])
    /// The relay to publish a components report of isufficient permissions to record the workout.
    private let insufficientPermissionRelay = PublishRelay<String>()
    /// The relay to publish a UI suspension command.
    private let uiSuspensionRelay = BehaviorRelay<Bool>(value: false)
    /// The relay to publish a suspension command.
    private let suspensionRelay = BehaviorRelay<Bool>(value: false)
    /// The relay to publish a reset command.
    private let resetRelay = PublishRelay<ORWorkoutInterface?>()
    
    /// A type containing all input data needed to establish a data flow.
    public struct Input {
        let readiness: Observable<WorkoutBuilderComponentStatus>?
        let insufficientPermission: Observable<String>?
        let statusSuggestion: Observable<WorkoutBuilder.Status>?
        let distance: Observable<Double>?
        let steps: Observable<Int?>?
        let currentLocation: Observable<TempWorkoutRouteDataSample?>?
        let locations: Observable<[TempWorkoutRouteDataSample]>?
        let altitudes: Observable<[AltitudeManagement.AltitudeSample]>?
        let heartRates: Observable<[TempWorkoutHeartRateDataSample]>?

        public init(readiness: Observable<WorkoutBuilderComponentStatus>? = nil, insufficientPermission: Observable<String>? = nil, statusSuggestion: Observable<Status>? = nil, distance: Observable<Double>? = nil, steps: Observable<Int?>? = nil, currentLocation: Observable<TempWorkoutRouteDataSample?>? = nil, locations: Observable<[TempWorkoutRouteDataSample]>? = nil, altitudes: Observable<[AltitudeManagement.AltitudeSample]>? = nil, heartRates: Observable<[TempWorkoutHeartRateDataSample]>? = nil) {
            self.readiness = readiness
            self.insufficientPermission = insufficientPermission
            self.statusSuggestion = statusSuggestion
            self.distance = distance
            self.steps = steps
            self.currentLocation = currentLocation
            self.locations = locations
            self.altitudes = altitudes
            self.heartRates = heartRates
        }
    }
    
    /// A type containing all output data needed to establish a data flow.
    public struct Output {
        let status: Observable<WorkoutBuilder.Status>
        let workoutType: Observable<Workout.WorkoutType>
        let startDate: Observable<Date?>
        let endDate: Observable<Date?>
        let distance: Observable<Double>
        let steps: Observable<Int?>
        let pauses: Observable<[TempWorkoutPause]>
        let currentLocation: Observable<TempWorkoutRouteDataSample?>
        let locations: Observable<[TempWorkoutRouteDataSample]>
        let altitudes: Observable<[AltitudeManagement.AltitudeSample]>
        let heartRates: Observable<[TempWorkoutHeartRateDataSample]>
        let insufficientPermission: Observable<String>
        let isUISuspended: Observable<Bool>
        let isSuspended: Observable<Bool>
        let onReset: Observable<ORWorkoutInterface?>
    }
    
    /**
     Tranforms the provided inputs to an output establishing a data flow between this WorkoutBuilder and the caller of this function.
     - parameter input: the input provided to the workout builder
     - returns: the output to provide the caller with the necessary data
     */
    public func tranform(_ input: WorkoutBuilder.Input) -> Output {
        
        input.readiness?.subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .preparing(let preparingType):
                guard !self.preparingComponents.contains(where: { $0 == preparingType }) else { return }
                self.preparingComponents.append(preparingType)
            case .ready(let preparingType):
                self.preparingComponents.removeAll(where: { $0 == preparingType })
            }
            let isReadyToRecord = self.preparingComponents.isEmpty
            let newStatus: Status = isReadyToRecord ? .ready : .waiting
            self.validateTransition(to: newStatus) { isValid in
                guard isValid else { return }
                self.statusRelay.accept(newStatus)
            }
        }).disposed(by: disposeBag)
        
        input.statusSuggestion?.subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            self.validateTransition(to: status) { (isValid) in
                guard isValid else { return }
                self.statusRelay.accept(status)
            }
        }).disposed(by: disposeBag)
        
        input.insufficientPermission?.bind(to: insufficientPermissionRelay).disposed(by: disposeBag)
        input.distance?.bind(to: distanceRelay).disposed(by: disposeBag)
        input.steps?.bind(to: stepsRelay).disposed(by: disposeBag)
        input.currentLocation?.bind(to: currentLocationRelay).disposed(by: disposeBag)
        input.locations?.bind(to: locationsRelay).disposed(by: disposeBag)
        input.altitudes?.bind(to: altitudesRelay).disposed(by: disposeBag)
        input.heartRates?.bind(to: heartRatesRelay).disposed(by: disposeBag)
        
        return Output(
            status: statusRelay.asBackgroundObservable(),
            workoutType: workoutTypeRelay.asBackgroundObservable(),
            startDate: startDateRelay.asBackgroundObservable(),
            endDate: endDateRelay.asBackgroundObservable(),
            distance: distanceRelay.asBackgroundObservable(),
            steps: stepsRelay.asBackgroundObservable(),
            pauses: pausesRelay.asBackgroundObservable(),
            currentLocation: currentLocationRelay.asBackgroundObservable(),
            locations: locationsRelay.asBackgroundObservable(),
            altitudes: altitudesRelay.asBackgroundObservable(),
            heartRates: heartRatesRelay.asBackgroundObservable(),
            insufficientPermission: insufficientPermissionRelay.asBackgroundObservable(),
            isUISuspended: uiSuspensionRelay.asBackgroundObservable(),
            isSuspended: suspensionRelay.asBackgroundObservable(),
            onReset: resetRelay.asBackgroundObservable()
        )
    }
    
    // MARK: - Preparation
    
    /// Resets the `WorkoutBuilder` and it's components and prepares tem for another recording.
    private func reset() {
        
        statusRelay.accept(.waiting)
        startDateRelay.accept(nil)
        endDateRelay.accept(nil)
        pausesRelay.accept([])
        resetRelay.accept(nil)
    }
    
    /**
     Continues a workout by setting up the `WorkoutBuilder` and it's components like they are recording.
     - parameter snapshot: the snapshot made of the continued workout
     */
    public func continueWorkout(from snapshot: TempWorkout) {
        
        startDateRelay.accept(snapshot.startDate)
        endDateRelay.accept(nil)
        pausesRelay.accept(snapshot.pauses.map { TempWorkoutPause(uuid: $0.uuid, startDate: $0.startDate, endDate: $0.endDate, pauseType: $0.pauseType) })
        lastPause = (type: .manual, startingAt: snapshot.endDate)
        resetRelay.accept(snapshot)
        self.validateTransition(to: .recording) { isValid in
            guard isValid else { return }
            self.statusRelay.accept(.recording)
        }
    }
    
    // MARK: - Validation
    
    /**
     Validates the transition to a new status
     - parameter newStatus: the new status the `WorkoutBuilder` is supposed to take on
     - parameter closure: the closure being performed with a boolean indicating if the transition is valid as an argument; the closure will not be called if the status is equal to the current one
     */
    private func validateTransition(to newStatus: WorkoutBuilder.Status, closure: (Bool) -> Void) {
        let oldStatus = self.statusRelay.value
        guard oldStatus != newStatus else { return }
        
        var isValid = false
        
        switch newStatus {
        case .recording: isValid = oldStatus != .waiting
        case .paused: isValid = [.recording, .autoPaused].contains(oldStatus)
        case .waiting: isValid = oldStatus == .ready
        case .ready: isValid = true
        case .autoPaused: isValid = oldStatus == .recording
        }
        
        closure(isValid)
    }
    
    // MARK: - ApplicationStateObserver
    
    /// Implementation of the `ApplicationStateObserver` protocol sending a suspension command to all subscribers when not recording to save battery life.
    func didUpdateApplicationState(to state: ApplicationState) {
        self.uiSuspensionRelay.accept(state == .background)
        guard !self.statusRelay.value.isActiveStatus else { return }
        self.suspensionRelay.accept(state == .background)
    }
    
}
