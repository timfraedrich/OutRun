import Combine
import CoreLocation
import Foundation
import OSLog
import Perception

@Observable
@RecordingActor
class WorkoutRecorderState {
    
    typealias Status = WorkoutRecorderStatus
    
    private let logger = Logger(category: "WorkoutRecorderState")
    
    private(set) var status: WorkoutRecorderStatus = .initializing
    // TODO: Use user preferred value.
    private(set) var workoutType: WorkoutType = .running
    private(set) var distance: Double = .zero
    private(set) var lastResumeDate: Date? = nil
    private(set) var activeDurationBeforeLastPause: TimeInterval = .zero
    private(set) var workoutIdentifier: UUID?
    /// The date at which the current recording process was started (workout first started or continued).
    private(set) var lastStartDate: Date?
    private(set) var lastLocation: CLLocation?
    /// The last location added to the workout route.
    /// - note: This value gets reset to `nil` if the workout gets paused to not falsify the distance.
    private(set) var lastRecordedLocation: CLLocation?
    /// The absolute altitude of the first location for which relative altitude changes were used to refine the altitude measurement.
    private(set) var baseAltitude: Double?
    private(set) var manuallyPausedSince: Date?
    private(set) var automaticallyPausedSince: Date?
    
    var activeDuration: WorkoutMetric.ValueRepresentation {
        guard status.isCollectingData, let lastResumeDate else { return .duration(0) }
        return if case .paused = status {
            .duration(activeDurationBeforeLastPause)
        } else {
            .increasingDuration(lastResumeDate, -activeDurationBeforeLastPause)
        }
    }
    
    var distanceMetric: WorkoutMetric.ValueRepresentation {
        guard status.isCollectingData else { return .longDistanceMeasurement(.init(value: 0, unit: .meters)) }
        return .longDistanceMeasurement(.init(value: distance, unit: .meters))
    }
    
    var energy: Double {
        Calculation.calculateBurnedEnergy(distance: distance, workoutType: workoutType)
    }
    
    init() {}
    
    func signalSuccessfulInitialization() throws(WorkoutRecorderError) {
        if case .failed = status {
            throw .inFailedState
        }
        status = .idle
    }
    
    func startOrContinue(_ workout: RawWorkout, on date: Date) async throws(WorkoutRecorderError) {
        try checkStatus()
        guard case .idle = status else { throw .alreadyRecording }
        workoutIdentifier = workout.id
        workoutType = workout.type
        distance = workout.distance
        lastStartDate = date
        lastResumeDate = date
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
        baseAltitude = nil
        manuallyPausedSince = nil
        automaticallyPausedSince = nil
        try transition(to: .idle)
        if case .paused(let manual) = status, let pausedSince = manual ? manuallyPausedSince : automaticallyPausedSince {
            return .init(startDate: pausedSince, endDate: date, userInitiated: manual)
        }
        return nil
    }
    
    func processLocation(
        _ location: CLLocation?,
        with altitude: AltitudeService.AltitudeSample?
    ) async throws -> (sample: RawWorkoutRouteDataSample?, pause: RawWorkoutPause?) {
        lastLocation = location
        guard status.isCollectingData,
              let workoutIdentifier,
              let location,
              location.timestamp > lastRecordedLocation?.timestamp ?? .distantPast,
              // TODO: Respect user selected location accuracy
              location.horizontalAccuracy < 20
        else { return (nil, nil) }
        var pause: RawWorkoutPause? = nil
        // TODO: Improve auto pause functionality.
        if let thresholds = workoutType.automaticPauseThresholds, location.speed >= 0 {
            if automaticallyPausedSince == nil, location.speed < thresholds.pauseThreshold {
                pause = try self.pause(manual: false, on: location.timestamp)
            } else if automaticallyPausedSince != nil, location.speed > thresholds.resumeThreshold {
                pause = try resume(manual: false, on: location.timestamp)
            }
        }
        let addedDistance: Double = if case .recording = status, let lastRecordedLocation {
            location.distance(from: lastRecordedLocation)
        } else {
            .zero
        }
        let newDistance = distance + addedDistance
        distance = newDistance
        let currentEnergy = Calculation.calculateBurnedEnergy(distance: newDistance, workoutType: workoutType)
        var sample = RawWorkoutRouteDataSample(from: location)
        refineSample(&sample, with: altitude)
        lastRecordedLocation = location
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
            lastRecordedLocation = nil
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
            lastRecordedLocation = nil
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
                logger.info("Resumed recording automatically.")
                return RawWorkoutPause(startDate: automaticallyPausedSince, endDate: date, userInitiated: false)
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
