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
    
    // MARK: - Static
    
    /**
     weak reference to the currently active `WorkoutBuilder` if there is any
     - note: ideally there should always only be one currently active `WorkoutBuilder`, because recording multiple workouts at once would not make any sense and multiple instances just take up more system memory
     */
    static weak var currentlyActive: WorkoutBuilder?
    
    // ============== TAKE A LOOK AT THIS ================== //
    /// a boolean indicating whether background updates should be performed
    public private(set) var shouldPerformBackgroundUpdates: Bool = true
    // ===================================================== //
    
    // MARK: Actions
    
    /**
     Starts or resumes the `WorkoutBuilder` if this action is appropriate
     - parameter completion: a closure with a success boolean as a parameter indicating if the action was performed
     */
    public func startOrResume(completion: @escaping (Bool) -> Void) {
        
        let completion = safeClosure(from: completion)
        let timestamp = Date()
        
        validateTransition(to: .recording) { (success) in
            guard success else { completion(false); return }
            
            if self.startDateRelay.value == nil {
                self.startDateRelay.accept(timestamp)
                
            } else if let lastPause = lastPause {
                let pause = TempWorkoutPause(uuid: nil, startDate: lastPause, endDate: timestamp, pauseType: .manual)
                let pauses = manualPauseRelay.value + [pause]
                self.manualPauseRelay.accept(pauses)
                self.lastPause = nil
            }
            
            self.statusRelay.accept(.recording)
            self.startPeriodicUpdates()
                
            completion(true)
        }
    }
    
    private var lastPause: Date?
    
    /**
     Pauses the `WorkoutBuilder` if this action is appropriate
     - parameter completion: a closure with a success boolean as a parameter indicating if the action was performed
     */
    public func pause(completion: @escaping (Bool) -> Void) {
        
        let completion = safeClosure(from: completion)
        let timestamp = Date()
        
        validateTransition(to: .paused) { (success) in
            guard success else { completion(false); return }
            
            self.lastPause = timestamp
            self.statusRelay.accept(.paused)
            completion(true)
        }
    }
    
    /**
     Stops and resets the `WorkoutBuilder` if this action is appropriate giving the recorded data to an instance of `WorkoutCompletionActionHandler`
     - parameter completion: a closure with a success boolean as a parameter indicating if the action was performed
     */
    public func finish(shouldProvideCompletionActions: Bool = true, completion: @escaping (Bool) -> Void) {
        
        let completion = safeClosure(from: completion)
        let timestamp = Date()
        
        validateTransition(to: .ready) { (success) in
            guard success else { completion(false); return }
            
            self.endDateRelay.accept(timestamp)
            
            if let snapshot = self.createSnapshot() {
                
                // NEEDS NEW APPROACH
                // let handler = WorkoutCompletionActionHandler(snapshot: snapshot, builder: self)
                // if shouldProvideCompletionActions {
                //     handler.display()
                // } else {
                //     handler.saveWorkout()
                // }
                
                completion(true)
              
            self.reset()
                
            } else {
                
                completion(false)
                
            }
            
        }
        
    }
    
    /**
     Continues a workout by setting up the `WorkoutBuilder` and its components like they never stopped recording
     - parameter snapshot: the snapshot made when finishing the workout
     */
    public func continueWorkout(from snapshot: TempWorkout) {
        
        let timestamp = Date()
        
        self.status = .recording
        self.startDate = snapshot.startDate
        self.endDate = nil
        
        let newPause = TempWorkoutEvent(type: .pause, date: snapshot.endDate)
        let newResume = TempWorkoutEvent(type: .resume, date: timestamp)
        
        self.manualPauseEvents = snapshot.workoutEvents
        self.manualPauseEvents.append(contentsOf: [newPause, newResume])
        
        performOnEveryComponent { (component) in
            
            component.continueWorkout(from: snapshot, timestamp: timestamp)
            
        }
        
        self.startPeriodicUpdates()
        
    }
    
    /**
     Notifies the `WorkoutBuilder` that its holding controller was dismissed and acts appropriately by stopping updates and resetting itself
     */
    public func actOnDismiss() {
        
        self.locationManagement.stopLocationUpdates()
        
        self.reset()
        
        if WorkoutBuilder.currentlyActive === self {
            WorkoutBuilder.currentlyActive = nil
        }
        
    }
    
    // MARK: Notifications from Components
    
    /**
     Notifies the `WorkoutBuilder` that the readiness status of one of its components changes
     */
    public func notifyOfReadinessChange() {
        
        let allReady = !self.components.contains { (component) -> Bool in
            !component.isReady
        }
        
        if self.status == .waiting && allReady && self.status != .ready {
            
            self.status = .ready
            
        } else if self.status == .ready && !allReady && self.status != .waiting {
            
            self.status = .waiting
            
        }
    }
    
    /**
     Notifies the `WorkoutBuilder` of a new by a component suggested status and validates the transition
     - parameter status: the suggestes new status
     - parameter closure: the closure being performed with a boolean indicating if the transition is valid as an argument; the closure will not be called if the suggested status is equal to the current one
     */
    public func suggestNewStatus(_ status: WorkoutBuilder.Status, closure: (Bool) -> Void) {
        
        self.validateTransition(to: status) { (isValid) in
            
            if isValid {
                self.status = status
                
                if status == .recording {
                    self.startPeriodicUpdates()
                }
                
            }
            
            closure(isValid)
            
        }
        
    }
    
    /**
     Notifies the `WorkoutBuilder` of a location update
     - parameter location: the last received location
     */
    public func notfiyOfLocationUpdate(with location: CLLocation) {
        
        self.liveUpdateLocations(withLast: location)
        self.liveUpdateSpeed()
        
        if self.status.isActiveStatus {
        
            self.autoPauseDetection.update(timestamp: location.timestamp, workoutType: self.workoutType, speed: location.speed)
            
        }
        
    }
    
    /**
     Notifies the `WorkoutBuilder` of a distance update
     */
    public func notifyOfDistanceUpdate() {
        
        self.liveUpdateDistance()
        
    }
    
    /**
     Notifies the `WorkoutBuilder` of missing permissions for location access during the recording of the workout
     */
    public func notifyOfInsufficientLocationPermission() {
        
        self.liveUpdateInsufficientPermission()
        
    }
    
    // MARK: Snapshot
    
    public func createSnapshot() -> TempWorkout? {
        
        guard self.status.isActiveStatus, let start = self.startDate else {
            return nil
        }
        
        let end = self.endDate ?? Date()
        var burnedEnergy: Double?
        if let userWeight = UserPreferences.weight.value {
            burnedEnergy = BurnedEnergyCalculator.calculateBurnedCalories(
                for: self.workoutType,
                distance: self.locationManagement.distance,
                weight: userWeight
                ).converting(to: UnitEnergy.standardUnit).value
        }
        let events = self.manualPauseEvents + AutoPause.convertToEvents(with: self.autoPauseDetection.getAutoPauses(with: end))
        let refinedLocations = self.altitudeManagement.refine(locations: self.locationManagement.locations)
        let routeData = refinedLocations.map { (location) -> TempWorkoutRouteDataSample in
            TempWorkoutRouteDataSample(clLocation: location)
        }
        
        return TempWorkout(
            uuid: nil,
            workoutType: self.workoutType.rawValue,
            startDate: start,
            endDate: end,
            distance: self.locationManagement.distance,
            steps: self.stepCounter.steps,
            isRace: false,
            isUserModified: false,
            comment: nil,
            burnedEnergy: burnedEnergy,
            healthKitUUID: nil,
            workoutEvents: events,
            locations: routeData,
            heartRates: []
        )
        
    }
    
    // MARK: - Protected
    
    /// The type of workout the `WorkoutBuilder` is supposed to record.
    fileprivate let workoutTypeRelay: BehaviorRelay<Workout.WorkoutType>
    /// The current status of the `WorkoutBuilder`.
    fileprivate let statusRelay = BehaviorRelay<WorkoutBuilder.Status>(value: .waiting)
    /// The date the recorded workout was started.
    fileprivate let startDateRelay = BehaviorRelay<Date?>(value: nil)
    /// The date the recorded workout was stopped.
    fileprivate let endDateRelay = BehaviorRelay<Date?>(value: nil)
    /// The pauses initiated by the app automatically.
    fileprivate let automaticPauseRelay = BehaviorRelay<[TempWorkoutPause]>(value: [])
    /// The pauses initiated by the user directly.
    fileprivate let manualPauseRelay = BehaviorRelay<[TempWorkoutPause]>(value: [])
    /// The action being performed upon a reset.
    fileprivate let resetRelay = PublishRelay<Void>()
    
    /**
     Starts a Timer updating the time elapsed and the energy burned every second while the status of `WorkoutBuilder` is `.recording`
     */
    private func startPeriodicUpdates() {
        
        Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.asyncInstance)
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            
            guard self.status == .recording else {
                timer.invalidate()
                return
            }
            
            self.liveUpdateDuration()
            self.liveUpdateBurnedEnergy()
        }
        
    }
    
    /**
     Resets the `WorkoutBuilder` and makes it ready for another recording
     */
    private func reset() {
        
        self.startDate = nil
        self.endDate = nil
        self.manualPauseEvents = []
        self.status = .waiting
        
        self.performOnEveryComponent { (component) in
            
            component.reset()
            
        }
        
        self.delegate?.resetAll()
        
        self.notifyOfReadinessChange()
        
    }
    
    // MARK: Components
    
    /// an array of the workout builder components to enable quick access for updates, etc.
    private var components: [WorkoutBuilderComponent] = []
    
    /// an instance of `AutoPauseDetection`
    public let autoPauseDetection = WorkoutBuilder.AutoPauseDetection()
    /// an instance of `LocationManagement`
    public let locationManagement = WorkoutBuilder.LocationManagement()
    /// an instance of `StepCounter`
    public let stepCounter = WorkoutBuilder.StepCounter()
    /// an instance of `AltitudeManagement`
    public let altitudeManagement = WorkoutBuilder.AltitudeManagement()
    
    /**
     Sets up the components in this instance of `WorkoutBuilder` by setting itself as the builder for them and adding each component to `components`
     - parameter components: the array of `WorkoutBuilderComponent`s the `WorkoutBuilder` is supposed to be set up with
     */
    private func setupComponents(with components: [WorkoutBuilderComponent]) {
        
        for component in components {
            
            component.builder = self
            
        }
        
        self.components = components
        
    }
    
    /**
     Performs an action in every component held in `components`
     - parameter closure: defines the action that is being performed
     */
    private func performOnEveryComponent(closure: (WorkoutBuilderComponent) -> Void) {
        
        for component in self.components {
            
            closure(component)
            
        }
        
    }
    
    // MARK: Status Validation
    
    /**
     Validates the transition to a new status
     - parameter newStatus: the new status the `WorkoutBuilder` is supposed to take on
     - parameter closure: the closure being performed with a boolean indicating if the transition is valid as an argument; the closure will not be called if the status is equal to the current one
     */
    private func validateTransition(to newStatus: WorkoutBuilder.Status, closure: (Bool) -> Void) {
        
        guard self.status != newStatus else {
            return
        }
        
        var isValid = false
        
        switch newStatus {
            
        case .recording:
            isValid = self.status != .waiting
            
        case .paused:
            isValid = [.recording, .autoPaused].contains(self.status)
            
        case .waiting:
            isValid = self.status == .ready
            
        case .ready:
            isValid = true
            
        case .autoPaused:
            isValid = self.status == .recording
            
        }
        
        closure(isValid)
        
    }
    
    // MARK: Background Suspension
    
    /// a protected boolean indicating whether background updates should be performed
    private var protectedShouldPerformBackgroundUpdates: Bool = true {
        didSet {
            self.delegate?.didUpdate(uiUpdatesSuspended: !self.shouldPerformBackgroundUpdates)
        }
    }
    
    /**
     Suspends background updates for `WorkoutBuilder` and its delegate
     */
    private func suspendBackgroundUpdates() {
        
        self.protectedShouldPerformBackgroundUpdates = false
        
    }
    
    /**
     Resumes background updates for `WorkoutBuilder` and its delegate
     */
    private func resumeBackgroundUpdates() {
        
        self.protectedShouldPerformBackgroundUpdates = true
        
        self.liveUpdateStatus()
        self.liveUpdateDistance()
        self.liveUpdateLocations(withLast: self.locationManagement.locations.last, force: true)
        self.liveUpdateDuration()
        self.liveUpdateSpeed()
        self.liveUpdateBurnedEnergy()
        
    }
    
    // MARK: - Initialisers
    
    /**
     Initialises a `WorkoutBuilder` instance
     - parameter workoutType: an optional of the type of workout that is supposed to be recorded; if `nil` the `WorkoutBuilder` sets it appropriately from `UserPreferences.standardWorkoutType`
     - parameter delegate: the delegate that is supposed to receive updates
     */
    public init(workoutType: Workout.WorkoutType? = nil, delegate: WorkoutBuilderDelegate) {
        
        self.workoutTypeRelay = BehaviorRelay(value: workoutType ?? Workout.WorkoutType(rawValue: UserPreferences.standardWorkoutType.value))
        
        self.delegate = delegate
        
        self.setupComponents(with: [autoPauseDetection, locationManagement, stepCounter, altitudeManagement])
        
        self.notifyOfReadinessChange()
        
        self.startObservingApplicationState()
        
        WorkoutBuilder.currentlyActive = self
        
    }
    
    // MARK: - ApplicationStateObserver - Protocol
    
    func didUpdateApplicationState(to state: ApplicationState) {
        
        switch state {
            
        case .foreground:
            
            self.resumeBackgroundUpdates()
            
            if !self.status.isActiveStatus {
                self.locationManagement.startLocationUpdates()
            }
            
        case .background:
            
            self.suspendBackgroundUpdates()
            
            if !self.status.isActiveStatus {
                self.locationManagement.stopLocationUpdates()
            }
            
        }
        
    }
    
    // MARK: - Reactive
    
    public struct Input {
        
    }
    
    public struct Output {
        
    }
    
    public func transform(input: Input) -> Output {
        
    }
    
    
}

