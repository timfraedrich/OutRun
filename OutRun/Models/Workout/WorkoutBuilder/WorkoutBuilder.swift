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
import Combine
import CombineExt

public class WorkoutBuilder: ApplicationStateObserver {
    
    // MARK: Public
    
    /// The current status of this `WorkoutBuilder` instance.
    public var status: Status { statusRelay.value }
    
    // MARK: - Internal
    
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
        
        let workoutType = workoutType ?? Workout.WorkoutType(rawValue: UserPreferences.standardWorkoutType.value)
        self.workoutTypeRelay = CurrentValueRelay(workoutType)
        
        self.prepareBindings()
        self.startObservingApplicationState()
    }
    
    // MARK: - Bindings
    
    private func prepareBindings() {
        
        // reacting to status changes
        statusRelay.sink(receiveValue: { [weak self] newStatus in
            guard let self else { return }
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
                
                if let snapshot = self.createSnapshot() {
                    let actionHandler = WorkoutCompletionActionHandler(snapshot: snapshot, builder: self)
                    actionHandler.display()
                }
                
                self.reset()
                
            default: // ignore everything else
                break
            }
        }).store(in: &cancellables)
        
    }
    
    // MARK: - Dataflow
    
    /// An Array of cancellables for subscription links to components and custom permanent subscriptions.
    private var cancellables: [AnyCancellable] = []
    
    /// The relay to publish the current status of the `WorkoutBuilder`.
    private let statusRelay = CurrentValueRelay<WorkoutBuilder.Status>(.waiting)
    /// The relay to publish the type of workout the `WorkoutBuilder` is supposed to record.
    private let workoutTypeRelay: CurrentValueRelay<Workout.WorkoutType>
    /// The relay to publish the date the recorded workout was started.
    private let startDateRelay = CurrentValueRelay<Date?>(nil)
    /// The relay to publish the date the recorded workout was stopped.
    private let endDateRelay = CurrentValueRelay<Date?>(nil)
    /// The relay to publish the distance shared by components.
    private let distanceRelay = CurrentValueRelay<Double>(0)
    /// The relay to publish the steps counted by components.
    private let stepsRelay = CurrentValueRelay<Int?>(nil)
    /// The relay to publish the pauses initiated by the user or by the app automaticallyprivate
    private let pausesRelay = CurrentValueRelay<[TempWorkoutPause]>([])
    /// The relay to publish the current location regardless of whether it was recorded or not.
    private let currentLocationRelay = CurrentValueRelay<TempWorkoutRouteDataSample?>(nil)
    /// The relay to publish the recorded locations received from components.
    private let locationsRelay = CurrentValueRelay<[TempWorkoutRouteDataSample]>([])
    /// The relay to publish the altitudes received from components.
    private let altitudesRelay = CurrentValueRelay<[AltitudeManagement.AltitudeSample]>([])
    /// The relay to publish the heart rate samples received from components.
    private let heartRatesRelay = CurrentValueRelay<[TempWorkoutHeartRateDataSample]>([])
    /// The relay to publish a components report of isufficient permissions to record the workout.
    private let insufficientPermissionRelay = PassthroughRelay<String>()
    /// The relay to publish a UI suspension command.
    private let uiSuspensionRelay = CurrentValueRelay<Bool>(false)
    /// The relay to publish a suspension command.
    private let suspensionRelay = CurrentValueRelay<Bool>(false)
    /// The relay to publish a reset command.
    private let resetRelay = PassthroughRelay<ORWorkoutInterface?>()
    
    /// A type containing all input data needed to establish a data flow.
    public struct Input {
        let readiness: AnyPublisher<WorkoutBuilderComponentStatus, Never>?
        let insufficientPermission: AnyPublisher<String, Never>?
        let workoutType: AnyPublisher<Workout.WorkoutType, Never>?
        let statusSuggestion: AnyPublisher<WorkoutBuilder.Status, Never>?
        let distance: AnyPublisher<Double, Never>?
        let steps: AnyPublisher<Int?, Never>?
        let currentLocation: AnyPublisher<TempWorkoutRouteDataSample?, Never>?
        let locations: AnyPublisher<[TempWorkoutRouteDataSample], Never>?
        let altitudes: AnyPublisher<[AltitudeManagement.AltitudeSample], Never>?
        let heartRates: AnyPublisher<[TempWorkoutHeartRateDataSample], Never>?

        public init(
            readiness: AnyPublisher<WorkoutBuilderComponentStatus, Never>? = nil,
            insufficientPermission: AnyPublisher<String, Never>? = nil,
            workoutType: AnyPublisher<Workout.WorkoutType, Never>? = nil,
            statusSuggestion: AnyPublisher<WorkoutBuilder.Status, Never>? = nil,
            distance: AnyPublisher<Double, Never>? = nil,
            steps: AnyPublisher<Int?, Never>? = nil,
            currentLocation: AnyPublisher<TempWorkoutRouteDataSample?, Never>? = nil,
            locations: AnyPublisher<[TempWorkoutRouteDataSample], Never>? = nil,
            altitudes: AnyPublisher<[AltitudeManagement.AltitudeSample], Never>? = nil,
            heartRates: AnyPublisher<[TempWorkoutHeartRateDataSample], Never>? = nil
        ) {
            self.readiness = readiness
            self.insufficientPermission = insufficientPermission
            self.workoutType = workoutType
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
        let status: AnyPublisher<WorkoutBuilder.Status, Never>
        let workoutType: AnyPublisher<Workout.WorkoutType, Never>
        let startDate: AnyPublisher<Date?, Never>
        let endDate: AnyPublisher<Date?, Never>
        let distance: AnyPublisher<Double, Never>
        let steps: AnyPublisher<Int?, Never>
        let pauses: AnyPublisher<[TempWorkoutPause], Never>
        let currentLocation: AnyPublisher<TempWorkoutRouteDataSample?, Never>
        let locations: AnyPublisher<[TempWorkoutRouteDataSample], Never>
        let altitudes: AnyPublisher<[AltitudeManagement.AltitudeSample], Never>
        let heartRates: AnyPublisher<[TempWorkoutHeartRateDataSample], Never>
        let insufficientPermission: AnyPublisher<String, Never>
        let isUISuspended: AnyPublisher<Bool, Never>
        let isSuspended: AnyPublisher<Bool, Never>
        let onReset: AnyPublisher<ORWorkoutInterface?, Never>
    }
    
    /**
     Tranforms the provided inputs to an output establishing a data flow between this WorkoutBuilder and the caller of this function.
     - parameter input: the input provided to the workout builder
     - returns: the output to provide the caller with the necessary data
     */
    public func tranform(_ input: WorkoutBuilder.Input) -> Output {
        
        input.readiness?.sink(receiveValue: readinessBinder).store(in: &cancellables)
        input.statusSuggestion?.sink(receiveValue: statusSuggestionBinder).store(in: &cancellables)
        input.insufficientPermission?.sink(receiveValue: insufficientPermissionRelay.accept).store(in: &cancellables)
        input.distance?.sink(receiveValue: distanceRelay.accept).store(in: &cancellables)
        input.steps?.sink(receiveValue: stepsRelay.accept).store(in: &cancellables)
        input.currentLocation?.sink(receiveValue: currentLocationRelay.accept).store(in: &cancellables)
        input.locations?.sink(receiveValue: locationsRelay.accept).store(in: &cancellables)
        input.altitudes?.sink(receiveValue: altitudesRelay.accept).store(in: &cancellables)
        input.heartRates?.sink(receiveValue: heartRatesRelay.accept).store(in: &cancellables)
        
        return Output(
            status: statusRelay.asBackgroundPublisher(),
            workoutType: workoutTypeRelay.asBackgroundPublisher(),
            startDate: startDateRelay.asBackgroundPublisher(),
            endDate: endDateRelay.asBackgroundPublisher(),
            distance: distanceRelay.asBackgroundPublisher(),
            steps: stepsRelay.asBackgroundPublisher(),
            pauses: pausesRelay.asBackgroundPublisher(),
            currentLocation: currentLocationRelay.asBackgroundPublisher(),
            locations: locationsRelay.asBackgroundPublisher(),
            altitudes: altitudesRelay.asBackgroundPublisher(),
            heartRates: heartRatesRelay.asBackgroundPublisher(),
            insufficientPermission: insufficientPermissionRelay.asBackgroundPublisher(),
            isUISuspended: uiSuspensionRelay.asBackgroundPublisher(),
            isSuspended: suspensionRelay.asBackgroundPublisher(),
            onReset: resetRelay.asBackgroundPublisher()
        )
    }
    
    /// A closure to update the readiness status of components.
    private var readinessBinder: (WorkoutBuilderComponentStatus) -> Void {
        return { [weak self] status in
            guard let self else { return }
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
        }
    }
    
    /// A closure to enable components to suggest a new status.
    private var statusSuggestionBinder: (WorkoutBuilder.Status) -> Void {
        return { [weak self] status in
            guard let self else { return }
            self.validateTransition(to: status) { (isValid) in
                guard isValid else { return }
                self.statusRelay.accept(status)
            }
        }
    }
    
    // MARK: - Create Snapshot
    
    /**
     Creates a snapshot of the workout currently under construction.
     - returns: a `TempWorkout` constructed from the recorded data; will be `nil` when start or end cannot be determined
     */
    private func createSnapshot() -> TempWorkout? {
        
        guard let start = startDateRelay.value, let end = endDateRelay.value else { return nil }
        
        return NewWorkout(
            workoutType: workoutTypeRelay.value,
            distance: distanceRelay.value,
            steps: stepsRelay.value,
            startDate: start,
            endDate: end,
            isRace: false,
            comment: nil,
            isUserModified: false,
            finishedRecording: true,
            heartRates: [],
            routeData: locationsRelay.value,
            pauses: pausesRelay.value,
            workoutEvents: []
        )
    }
    
    // MARK: - Preparation
    
    /// Resets the `WorkoutBuilder` and it's components and prepares them for another recording.
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
