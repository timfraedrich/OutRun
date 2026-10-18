//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Combine
import CoreLocation
import Foundation
import OSLog
import Perception

@Observable
@BackgroundActor
class WorkoutRecorderState {
    
    typealias Status = WorkoutRecorderStatus
    
    private static let minimumDistance: CLLocationDistance = 5
    private static let minimumTimeDifference: TimeInterval = 0.5
    private static let maximumTimeDifference: TimeInterval = 10
    
    private let logger = Logger(category: "WorkoutRecorderState")
    @ObservationIgnored private let userPreferences: UserPreferences
    
    private(set) var status: WorkoutRecorderStatus = .initializing
    private(set) var user: RawUser
    private(set) var workoutType: WorkoutType
    private(set) var distance: Double = .zero
    private var lastResumeDate: Date? = nil
    private var activeDurationBeforeLastPause: TimeInterval = .zero
    private(set) var workoutIdentifier: UUID?
    /// The date at which the current recording process was started (workout first started or continued).
    private(set) var lastStartDate: Date?
    private var lastLocation: CLLocation?
    /// The last location added to the workout route, including locations recorded during a pause.
    private var lastRecordedLocation: CLLocation?
    /// The last location added to the workout route while not paused, used to calculate the live metrics.
    /// - note: This value gets reset to `nil` if the workout gets paused to not falsify the distance.
    private var lastActiveLocation: CLLocation?
    /// The absolute altitude of the first location for which relative altitude changes were used to refine the altitude measurement.
    private var baseAltitude: Double?
    private var manuallyPausedSince: Date?
    private var automaticallyPausedSince: Date?
    
    private(set) var route: [CLLocationCoordinate2D] = []
    
    private var rollingDistance: Double = .zero
    private var rollingDuration: TimeInterval = .zero
    private var rollingSpeedSamples: [(addedDistance: Double, addedDuration: TimeInterval)] = []
    
    var activeDuration: DynamicTimeInterval {
        guard status.isCollectingData, let lastResumeDate else { return .constant(0) }
        return if case .paused = status {
            .constant(activeDurationBeforeLastPause)
        } else {
            .increasing(since: lastResumeDate, offset: -activeDurationBeforeLastPause)
        }
    }
    
    var distanceMeasurement: Measurement<UnitLength> {
        guard status.isCollectingData else { return .init(value: 0, unit: .meters) }
        return .init(value: distance, unit: .meters)
    }
    
    var energy: Double? { Calculation.calculateBurnedEnergy(weight: user.weight, distance: distance, workoutType: workoutType) }
    var energyMeasurement: Measurement<UnitEnergy> {
        guard let energy else { return .init(value: 0, unit: .joules) }
        return .init(value: energy, unit: .joules)
    }
    
    var speedMeasurement: Measurement<UnitSpeed> {
        let speed = if status.isCollectingData, userPreferences.calculateRollingSpeed, rollingDistance > .zero, rollingDuration > .zero {
            rollingDistance / rollingDuration
        } else if status.isCollectingData, let lastLocation, lastLocation.speed >= .zero {
            lastLocation.speed
        } else {
            CLLocationSpeed.zero
        }
        return .init(value: speed, unit: .metersPerSecond)
    }
    
    init(user: RawUser, latestWorkoutType: WorkoutType?) {
        self.user = user
        self.userPreferences = .init(preferences: user.preferences)
        self.workoutType = userPreferences.defaultWorkoutType ?? latestWorkoutType ?? .running
    }
    
    func signalSuccessfulInitialization() throws(WorkoutRecorderError) {
        if case .failed = status {
            throw .inFailedState
        }
        status = .idle
    }
    
    func update(basedOn updatedUser: RawUser) {
        user = updatedUser
        userPreferences.update(basedOn: updatedUser.preferences)
    }
    
    func changeWorkoutType(to type: WorkoutType) {
        workoutType = type
    }
    
    func startOrContinue(_ workout: RawWorkout, on date: Date) throws(WorkoutRecorderError) {
        try checkStatus()
        guard case .idle = status else { throw .alreadyRecording }
        workoutIdentifier = workout.id
        workoutType = workout.type
        distance = workout.distance
        lastStartDate = date
        lastResumeDate = date
        route = workout.route.map(\.coordinate)
        // TODO: add restore of rollingDistance, rollingDuration and rollingSpeedSamples
        if let lastPause = workout.pauses.max(by: { $0.endDate < $1.endDate }) {
            let lastActiveDuration = Calculation.calculateActiveDuration(
                startDate: workout.startDate,
                endDate: lastPause.endDate,
                pauses: workout.pauses
            ) ?? .zero
            activeDurationBeforeLastPause = lastActiveDuration
        }
        if let thresholds = workoutType.automaticPauseThresholds,
           let location = lastLocation,
           location.speed >= .zero,
           location.speed < thresholds.pauseThreshold
        {
            automaticallyPausedSince = date
            try transition(to: .paused(manual: false))
        } else {
            try transition(to: .recording)
        }
    }
    
    func pause(on date: Date) throws(WorkoutRecorderError) -> RawWorkoutPause? {
        try pause(manual: true, on: date)
    }
    
    func resume(on date: Date) throws(WorkoutRecorderError) -> RawWorkoutPause? {
        try resume(manual: true, on: date)
    }
    
    func end(on date: Date) throws(WorkoutRecorderError) -> RawWorkoutPause? {
        try checkStatus()
        guard status.isCollectingData else { throw WorkoutRecorderError.notRecording }
        distance = .zero
        lastResumeDate = nil
        activeDurationBeforeLastPause = .zero
        workoutIdentifier = nil
        lastStartDate = nil
        lastRecordedLocation = nil
        lastActiveLocation = nil
        baseAltitude = nil
        manuallyPausedSince = nil
        automaticallyPausedSince = nil
        route.removeAll()
        rollingDistance = .zero
        rollingDuration = .zero
        rollingSpeedSamples.removeAll()
        try transition(to: .idle)
        if case .paused(let manual) = status, let pausedSince = manual ? manuallyPausedSince : automaticallyPausedSince {
            return .init(startDate: pausedSince, endDate: date, userInitiated: manual)
        }
        return nil
    }
    
    func processLocation(
        _ location: CLLocation?,
        with altitude: AltitudeService.AltitudeSample?
    ) throws -> (sample: RawWorkoutRouteDataSample?, pause: RawWorkoutPause?) {
        lastLocation = location
        guard status.isCollectingData,
              let location,
              location.timestamp > lastRecordedLocation?.timestamp ?? .distantPast,
              location.horizontalAccuracy < userPreferences.requiredGPSAccuracy
        else { return (nil, nil) }
        var pause: RawWorkoutPause? = nil
        // TODO: Improve auto pause functionality.
        if userPreferences.pauseAutomatically, let thresholds = workoutType.automaticPauseThresholds, location.speed >= 0 {
            if automaticallyPausedSince == nil, location.speed < thresholds.pauseThreshold {
                pause = try self.pause(manual: false, on: location.timestamp)
            } else if automaticallyPausedSince != nil, location.speed > thresholds.resumeThreshold {
                pause = try resume(manual: false, on: location.timestamp)
            }
        }
        if let lastRecordedLocation {
            let distanceSinceLastSample = location.distance(from: lastRecordedLocation)
            let durationSinceLastSample = lastRecordedLocation.timestamp.distance(to: location.timestamp)
            guard durationSinceLastSample >= Self.minimumTimeDifference
                    && (distanceSinceLastSample > Self.minimumDistance || durationSinceLastSample > Self.maximumTimeDifference)
            else { return (nil, pause) }
        }
        var sample = RawWorkoutRouteDataSample(from: location)
        refineSample(&sample, with: altitude)
        route.append(location.coordinate)
        lastRecordedLocation = location
        guard case .recording = status else { return (sample, pause) }
        let addedDistance = lastActiveLocation.map { location.distance(from: $0) } ?? .zero
        let addedDuration = lastActiveLocation.map { $0.timestamp.distance(to: location.timestamp) } ?? .zero
        lastActiveLocation = location
        rollingSpeedSamples.append((addedDistance, addedDuration))
        var newRollingDistance = rollingDistance + addedDistance
        var newRollingDuration = rollingDuration + addedDuration
        var index = Int.zero
        while newRollingDistance > 1000, index < rollingSpeedSamples.count {
            guard let sample = rollingSpeedSamples[safeIndex: index] else { break }
            newRollingDistance -= sample.addedDistance
            newRollingDuration -= sample.addedDuration
            index += 1
        }
        if index > .zero { rollingSpeedSamples.removeFirst(index) }
        rollingDistance = newRollingDistance
        rollingDuration = newRollingDuration
        let newDistance = distance + addedDistance
        distance = newDistance
        return (sample, pause)
    }
    
    // MARK: Private
    
    private func pause(manual: Bool, on date: Date = .now) throws(WorkoutRecorderError) -> RawWorkoutPause? {
        try checkStatus()
        guard status.isCollectingData else { throw .notRecording }
        guard status != .paused(manual: true) else { throw .alreadyPaused }
        if manual {
            guard manuallyPausedSince == nil else { throw .alreadyPaused }
            manuallyPausedSince = date
            lastActiveLocation = nil
            try transition(to: .paused(manual: manual))
            logger.info("Paused recording manually.")
            if let automaticallyPausedSince {
                logger.info("Ended running automatic pause.")
                return RawWorkoutPause(startDate: automaticallyPausedSince, endDate: date, userInitiated: false)
            } else {
                updateActiveDurationBeforeLastPause(for: date)
            }
        } else {
            guard automaticallyPausedSince == nil else { throw .alreadyPaused }
            automaticallyPausedSince = date
            lastActiveLocation = nil
            if case .paused(manual: true) = status {
                logger.info("Detected automatic pause during manual pause, will transition if manual pause ends.")
            } else {
                try transition(to: .paused(manual: manual))
                updateActiveDurationBeforeLastPause(for: date)
                logger.info("Paused recording automatically.")
            }
        }
        return nil
    }
    
    private func resume(manual: Bool, on date: Date = .now) throws(WorkoutRecorderError) -> RawWorkoutPause? {
        try checkStatus()
        guard status.isCollectingData else { throw WorkoutRecorderError.notRecording }
        guard case .paused = status else { throw WorkoutRecorderError.notRecording }
        if manual {
            guard let manuallyPausedSince else { throw WorkoutRecorderError.notPaused }
            self.manuallyPausedSince = nil
            if automaticallyPausedSince != nil {
                self.automaticallyPausedSince = date
                try transition(to: .paused(manual: false))
                logger.info("Resumed manual pause and paused automatically.")
            } else {
                try transition(to: .recording)
                lastResumeDate = date
                logger.info("Resumed recording automatically.")
            }
            return RawWorkoutPause(startDate: manuallyPausedSince, endDate: date, userInitiated: true)
        } else {
            guard let automaticallyPausedSince else { throw WorkoutRecorderError.notPaused }
            self.automaticallyPausedSince = nil
            if case .paused(manual: true) = status {
                logger.info("Detected automatic resume during manual pause.")
            } else {
                try transition(to: .recording)
                lastResumeDate = date
                if automaticallyPausedSince.distance(to: date) >= 5 {
                    logger.info("Resumed recording automatically.")
                    return RawWorkoutPause(startDate: automaticallyPausedSince, endDate: date, userInitiated: false)
                } else {
                    logger.info("Resumed recording automatically and discarded pause due to low duration.")
                }
            }
        }
        return nil
    }
    
    private func updateActiveDurationBeforeLastPause(for pauseDate: Date) {
        guard let lastResumeDate else { return }
        let activeDuration = activeDurationBeforeLastPause + lastResumeDate.distance(to: pauseDate)
        activeDurationBeforeLastPause = activeDuration
    }
    
    private func transition(to newStatus: Status) throws(WorkoutRecorderError) {
        try checkStatus()
        guard status != newStatus else { return }
        switch (status, newStatus) {
        case (.recording, .idle), (.paused, .idle), (.idle, .recording), (.idle, .paused),
            (.recording, .paused), (.paused, .recording), (.paused, .paused):
            break
        case (_, .failed(let error)):
            logger.critical("Failed internally: \((error as CustomDebugStringConvertible).debugDescription).")
        default:
            logger.fault("Tried to illegally transition from status \(self.status.debugDescription) to \(newStatus.debugDescription).")
            throw .invalidStatusTransition
        }
        status = newStatus
        logger.info("Transitioned to status \(newStatus.debugDescription).")
    }
    
    private func checkStatus() throws(WorkoutRecorderError) {
        if case .failed = status {
            throw .inFailedState
        } else if case .initializing = status {
            throw .notInitialized
        }
    }
    
    private func refineSample(_ sample: inout RawWorkoutRouteDataSample, with altitudeSample: AltitudeService.AltitudeSample?) {
        guard let altitudeSample else { return }
        if altitudeSample.isAbsolute {
            sample.altitude = Float(altitudeSample.altitude)
        } else if let baseAltitude {
            sample.altitude = Float(baseAltitude + altitudeSample.altitude)
        } else {
            baseAltitude = Double(sample.altitude) + altitudeSample.altitude
        }
    }
}
