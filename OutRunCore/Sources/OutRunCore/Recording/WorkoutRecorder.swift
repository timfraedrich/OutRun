import Combine
import CoreLocation
import Foundation
import OSLog

/// A class responsible for recording workouts.
/// - warning: Before this class can be used make sure to gather user authorization for at least location data and optionally altitude and
/// step data.
public class WorkoutRecorder {
    
    private let logger = Logger(category: "WorkoutRecorder")
    private let processingQueue = DispatchQueue(label: "WorkoutRecorderProcessingQueue")
    private var cancellables: Set<AnyCancellable> = []
    
    private let database: Database
    private let locationService: LocationService
    private let altitudeService: AltitudeService
    private let stepService: StepService
    
    private let statusSubject = CurrentValueSubject<Status, Never>(.initializing)
    // TODO: Use user preferred value.
    private let workoutTypeSubject = CurrentValueSubject<WorkoutType, Never>(.running)
    private var workoutIdentifier: UUID?
    private var lastStartDate: Date?
    private var distance: Double = .zero
    private var lastRecordedLocation: CLLocation?
    /// The absolute altitude of the first location for which relative altitude changes were used to refine the altitude measurement.
    private var baseAltitude: Double?
    private var manuallyPausedSince: Date?
    private var automaticallyPausedSince: Date?
    
    public var status: Status { statusSubject.value }
    public var statusPublisher: some Publisher<Status, Never> { statusSubject.eraseToAnyPublisher() }
    public var workoutType: WorkoutType { workoutTypeSubject.value }
    public var workoutTypePublisher: some Publisher<WorkoutType, Never> { workoutTypeSubject.eraseToAnyPublisher() }
    
    // TODO: Add restore of running workout
    init(database: Database, locationService: LocationService, altitudeService: AltitudeService, stepService: StepService) {
        self.database = database
        self.locationService = locationService
        self.altitudeService = altitudeService
        self.stepService = stepService
        prepareSubscriptions()
        statusSubject.send(.idle)
        logger.info("Initialized.")
    }
    
    /// Starts the recording process for a workout.
    /// - throws: This method fails if this class has not been initialized or is currently in a failed or recording state.
    public func startRecording() async throws {
        try await startOrContinueWorkout(with: nil)
    }
    
    /// Continues the recording process for a workout that has previously been ended.
    public func continueRecording(with identifier: UUID) async throws {
        try await startOrContinueWorkout(with: identifier)
    }
    
    /// Pauses the recording process to be resumed in the near future.
    /// - throws: If the transition to a
    /// - note: Data will be collected even while paused, but ignored in the statistic calculation.
    public func pauseRecording() async throws {
        do {
            guard let workoutIdentifier, let pause = try pause(manual: true) else { return }
            try await database.addPause(pause, toWorkoutWith: workoutIdentifier)
        } catch {
            logger.error("Failed to manually pause recording: \((error as CustomDebugStringConvertible).debugDescription).")
        }
    }
    
    /// Resumes the recording process after being paused through ``pauseRecording()``.
    public func resumeRecording() async throws {
        do {
            guard let workoutIdentifier, let pause = try resume(manual: true) else { return }
            try await database.addPause(pause, toWorkoutWith: workoutIdentifier)
        } catch {
            logger.error("Failed to manually resume recording: \((error as CustomDebugStringConvertible).debugDescription).")
        }
    }
    
    /// Ends the recording process and resets the workout recorder for the next recording.
    /// - returns: The finalized recorded workout if data was collected, `nil` otherwise.
    /// - throws: If this class is currently not recording a workout.
    public func endRecording() async throws -> RawWorkout? {
        try checkStatus()
        guard status.isCollectingData, let workoutIdentifier else { throw WorkoutRecorderError.notRecording }
        let now = Date.now
        if case .paused(let manual) = status, let pausedSince = manual ? manuallyPausedSince : automaticallyPausedSince {
            let pause = RawWorkoutPause(startDate: pausedSince, endDate: now, userInitiated: manual)
            try await database.addPause(pause, toWorkoutWith: workoutIdentifier)
        }
        let workout = try await database.finalizeWorkout(with: workoutIdentifier, endDate: now)
        try transition(to: .idle)
        return workout
    }
    
    // MARK: Internal
    
    private func startOrContinueWorkout(with identifier: UUID?) async throws {
        do {
            try checkStatus()
            try checkLocationAuthorization()
            guard case .idle = status else { throw WorkoutRecorderError.alreadyRecording }
            let now = Date.now
            if let identifier {
                let workout = try await database.continueWorkout(with: identifier, continueDate: now)
                workoutIdentifier = identifier
                distance = workout.distance
                workoutTypeSubject.send(workout.type)
            } else {
                let identifier = try await database.initializeWorkout(with: workoutType, startDate: now)
                workoutIdentifier = identifier
            }
            lastStartDate = now
            if let thresholds = workoutType.automaticPauseThresholds,
               let location = locationService.lastLocation,
               location.speed >= 0,
               location.speed < thresholds.pauseThreshold {
                automaticallyPausedSince = now
                try transition(to: .paused(manual: false))
            } else {
                try transition(to: .recording)
            }
            logger.info("\(identifier == nil ? "Started" : "Continued") recording workout.")
        } catch {
            let errorDescription = (error as CustomDebugStringConvertible).debugDescription
            logger.error("Failed to \(identifier == nil ? "start" : "continue") recording workout: \(errorDescription).")
            throw error
        }
    }
    
    private func pause(manual: Bool, for date: Date = .now) throws -> RawWorkoutPause? {
        guard status.isCollectingData else { throw WorkoutRecorderError.notRecording }
        if manual {
            guard manuallyPausedSince == nil else { throw WorkoutRecorderError.alreadyPaused }
            manuallyPausedSince = date
            try transition(to: .paused(manual: manual))
            logger.info("Paused recording manually.")
            if let automaticallyPausedSince {
                logger.info("Ended running automatic pause.")
                return RawWorkoutPause(startDate: automaticallyPausedSince, endDate: date, userInitiated: false)
            }
        } else {
            guard automaticallyPausedSince == nil else { throw WorkoutRecorderError.alreadyPaused }
            automaticallyPausedSince = date
            if case .paused(manual: true) = status {
                logger.info("Detected automatic pause during manual pause, will transition if manual pause ends.")
            } else {
                try transition(to: .paused(manual: manual))
                logger.info("Paused recording automatically.")
            }
        }
        return nil
    }
    
    private func autoPause(for date: Date) {
        do {
            guard let workoutIdentifier, let pause = try pause(manual: false, for: date) else { return }
            syncAddPause(pause, toWorkoutWith: workoutIdentifier)
        } catch {
            logger.error("Failed to automatically pause workout: \((error as CustomDebugStringConvertible).debugDescription).")
        }
    }
    
    private func resume(manual: Bool, for date: Date = .now) throws -> RawWorkoutPause? {
        guard status.isCollectingData else { throw WorkoutRecorderError.notRecording }
        if manual {
            guard let manuallyPausedSince else { throw WorkoutRecorderError.notPaused }
            self.manuallyPausedSince = nil
            if automaticallyPausedSince != nil {
                self.automaticallyPausedSince = date
                try transition(to: .paused(manual: false))
                logger.info("Resumed manual pause and paused automatically.")
            } else {
                try transition(to: .recording)
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
                logger.info("Resumed recording automatically.")
                return RawWorkoutPause(startDate: automaticallyPausedSince, endDate: date, userInitiated: false)
            }
        }
        return nil
    }
    
    private func autoResume(for date: Date) {
        do {
            guard let workoutIdentifier, let pause = try resume(manual: false, for: date) else { return }
            syncAddPause(pause, toWorkoutWith: workoutIdentifier)
        } catch {
            logger.error("Failed to automatically resume workout: \((error as CustomDebugStringConvertible).debugDescription).")
        }
    }
    
    private func syncAddPause(_ pause: RawWorkoutPause, toWorkoutWith workoutIdentifier: UUID) {
        Task { [database, logger] in
            do {
                try await database.addPause(pause, toWorkoutWith: workoutIdentifier)
            } catch {
                logger.error("Failed to save pause: \((error as CustomDebugStringConvertible).debugDescription).")
            }
        }
    }
    
    private func reset() {
        workoutIdentifier = nil
        lastStartDate = nil
        distance = .zero
        lastRecordedLocation = nil
        baseAltitude = nil
        manuallyPausedSince = nil
        automaticallyPausedSince = nil
        logger.info("Finished resetting internally.")
    }
    
    private func transition(to newStatus: Status) throws(WorkoutRecorderError) {
        try checkStatus()
        guard status != newStatus else { return }
        switch (status, newStatus) {
        case (.recording, .idle), (.paused, .idle):
            reset()
        case (.idle, .recording), (.idle, .paused), (.recording, .paused), (.paused, .recording), (.paused, .paused):
            break
        case (_, .failed(let error)):
            logger.critical("Failed internally: \((error as CustomDebugStringConvertible).debugDescription).")
        default:
            logger.fault("Tried to illegally transition from status \(self.status.debugDescription) to \(newStatus.debugDescription).")
            throw .invalidStatusTransition
        }
        statusSubject.send(newStatus)
        logger.info("Transitioned to status \(newStatus.debugDescription).")
    }
    
    private func checkStatus() throws(WorkoutRecorderError) {
        if case .failed = status {
            throw .inFailedState
        } else if case .initializing = status {
            throw .notInitialized
        }
    }
    
    private func checkLocationAuthorization() throws(WorkoutRecorderError) {
        if !locationService.status.locationAuthorizationSufficient {
            throw .locationAuthorizationInsufficient
        }
    }
    
    // MARK: Subscriptions
    
    private func prepareSubscriptions() {
        statusSubject.receive(on: processingQueue).sink(receiveValue: statusBinder).store(in: &cancellables)
        locationService.lastLocationPublisher.receive(on: processingQueue).sink(receiveValue: lastLocationBinder).store(in: &cancellables)
    }
    
    private var statusBinder: (Status) -> Void {
        { [weak self] status in
            guard let self else { return }
            locationService.changeMode(to: status.isCollectingData ? .recording : .idle)
            if altitudeService.mode.altitudeAvailable {
                if status.isCollectingData, !altitudeService.status.isCollectingData {
                    altitudeService.start()
                } else if !status.isCollectingData, altitudeService.status.isCollectingData {
                    altitudeService.reset()
                }
            }
            if stepService.stepsAvailable {
                if status.isCollectingData, !stepService.status.isCollectingData, let lastStartDate {
                    stepService.start(from: lastStartDate)
                } else if !status.isCollectingData, stepService.status.isCollectingData {
                    stepService.reset()
                }
            }
        }
    }
    
    private var lastLocationBinder: (CLLocation?) -> Void {
        { [weak self] location in
            guard let self,
                  status.isCollectingData,
                  let workoutIdentifier,
                  let location,
                  location.timestamp > lastRecordedLocation?.timestamp ?? .distantPast,
                  // TODO: Respect user selected location accuracy
                  location.horizontalAccuracy < 20
            else { return }
            // TODO: Improve auto pause functionality.
            if let thresholds = workoutType.automaticPauseThresholds, location.speed >= 0 {
                if automaticallyPausedSince == nil, location.speed < thresholds.pauseThreshold {
                    autoPause(for: location.timestamp)
                } else if automaticallyPausedSince != nil, location.speed > thresholds.resumeThreshold {
                    autoResume(for: location.timestamp)
                }
            }
            let addedDistance: Double = if case .recording = status, let lastRecordedLocation {
                location.distance(from: lastRecordedLocation)
            } else {
                .zero
            }
            distance += addedDistance
            let currentStepCount = stepService.stepCount
            let currentEnergy = Calculation.calculateBurnedEnergy(distance: distance, workoutType: workoutType)
            var sample = RawWorkoutRouteDataSample(from: location)
            sample.altitude = Float(refineAltitude(location.altitude))
            lastRecordedLocation = location
            Task { [database] in
                try await database.addRouteSample(
                    sample,
                    toWorkoutWith: workoutIdentifier,
                    addedDistance: addedDistance,
                    updatedEnergy: currentEnergy,
                    updatedRepetitions: currentStepCount
                )
            }
        }
    }
    
    private func refineAltitude(_ altitude: Double) -> Double {
        if let lastAltitude = altitudeService.lastAltitude {
            if lastAltitude.isAbsolute {
                return lastAltitude.altitude
            } else if let baseAltitude {
                return baseAltitude + lastAltitude.altitude
            } else {
                baseAltitude = altitude
            }
        }
        return altitude
    }
    
    // MARK: - WorkoutRecorderError
    
    public enum WorkoutRecorderError: LocalizedError, Equatable, CustomDebugStringConvertible {
        
        case alreadyRecording
        case inFailedState
        case notInitialized
        case notRecording
        case notPaused
        case alreadyPaused
        case locationAuthorizationInsufficient
        case invalidStatusTransition
        
        public var debugDescription: String {
            switch self {
            case .alreadyRecording: "WorkoutRecorderError.alreadyRecording"
            case .inFailedState: "WorkoutRecorderError.inFailedState"
            case .notInitialized: "WorkoutRecorderError.notInitialized"
            case .notRecording: "WorkoutRecorderError.notRecording"
            case .notPaused: "WorkoutRecorderError.notPaused"
            case .alreadyPaused: "WorkoutRecorderError.alreadyPaused"
            case .locationAuthorizationInsufficient: "WorkoutRecorderError.locationAuthorizationInsufficient"
            case .invalidStatusTransition: "WorkoutRecorderError.invalidStatusTransition"
            }
        }
        
        public var errorDescription: String? {
            switch self {
            case .alreadyRecording: R.string.localizable.workout_recorder_error_already_recording()
            case .inFailedState: R.string.localizable.workout_recorder_error_in_failed_state()
            case .notInitialized: R.string.localizable.workout_recorder_error_not_initialized()
            case .notRecording: R.string.localizable.workout_recorder_error_not_recording()
            case .notPaused: R.string.localizable.workout_recorder_error_not_paused()
            case .alreadyPaused: R.string.localizable.workout_recorder_error_already_paused()
            case .locationAuthorizationInsufficient: R.string.localizable.workout_recorder_error_location_authorization_insufficient()
            case .invalidStatusTransition: R.string.localizable.workout_recorder_error_invalid_status_transition()
            }
        }
    }
    
    // MARK: - Status
    
    public enum Status: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
        
        /// Preparing functionality.
        case initializing
        /// Ready to start recording, given that location access was provided.
        case idle
        /// Currently recording.
        case recording
        /// Currently recording, but not adding to distance or time. Boolean value indicates whether the pause was user initiated.
        case paused(manual: Bool)
        /// Failed with the specified error.
        case failed(Error)
        
        public var description: String {
            switch self {
            case .initializing: R.string.localizable.workout_recorder_status_initializing()
            case .idle: R.string.localizable.workout_recorder_status_idle()
            case .recording: R.string.localizable.workout_recorder_status_recording()
            case .paused(let manual):
                if manual {
                    R.string.localizable.workout_recorder_status_paused_manual()
                } else {
                    R.string.localizable.workout_recorder_status_paused_automatic()
                }
            case .failed: R.string.localizable.workout_recorder_status_failed()
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .initializing: "WorkoutRecorder.Status.initializing"
            case .idle: "WorkoutRecorder.Status.idle"
            case .recording: "WorkoutRecorder.Status.recording"
            case .paused(manual: let manual): "WorkoutRecorder.Status.paused(manual: \(manual))"
            case .failed(let error): "WorkoutRecorder.Status.failed(\((error as CustomDebugStringConvertible).debugDescription))"
            }
        }
        
        public var isCollectingData: Bool {
            switch self {
            case .recording, .paused: true
            default: false
            }
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.initializing, .initializing), (.idle, .idle), (.recording, .recording), (.failed, .failed): true
            case (.paused(let lhsManual), .paused(manual: let rhsManual)): lhsManual == rhsManual
            default: false
            }
        }
    }
}
