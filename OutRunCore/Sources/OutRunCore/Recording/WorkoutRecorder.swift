import Combine
import CoreLocation
import Foundation
import OSLog
import Perception

/// A class for recording and monitoring the progress of a workout.
/// - warning: Before this class can be used make sure to gather user authorization for at least location data and optionally altitude and
/// step data.
@MainActor
public class WorkoutRecorder: ObservableObject {
    
    public typealias Status = WorkoutRecorderStatus
    
    private let logger = Logger(category: "WorkoutRecorder")
    private var cancellables = Set<AnyCancellable>()
    // user profile (weight, sex, etc.)
    // user preferences
    private let state: WorkoutRecorderState
    private let database: Database
    private let locationService: LocationService
    private let altitudeService: AltitudeService?
    private let stepService: StepService?
    
    @Published public private(set) var status: Status = .initializing
    @Published public private(set) var workoutType: WorkoutType
    @Published public private(set) var distance: WorkoutMetric.ValueRepresentation
    @Published public private(set) var duration: WorkoutMetric.ValueRepresentation
    
    init(database: Database, locationService: LocationService, altitudeService: AltitudeService?, stepService: StepService?) async {
        
        self.state = await .init()
        self.database = database
        self.locationService = locationService
        self.altitudeService = altitudeService
        self.stepService = stepService
        
        self.workoutType = await state.workoutType
        self.distance = await state.distanceMetric
        self.duration = await state.activeDuration
        await startStreamingUpdates()
        
        do {
            try await state.signalSuccessfullInitialization()
        } catch {
            logger.critical("Failed to transition state to idle status: \((error as CustomDebugStringConvertible).debugDescription).")
        }
        
        do {
            let date: Date = .now
            if let workout = try await database.recoverUnfinishedWorkout(recoveryDate: date) {
                try await state.startOrContinue(workout, on: date)
            }
        } catch {
            logger.error("Failed to recover unfinished workout: \((error as CustomDebugStringConvertible).debugDescription).")
        }
    }
    
    @RecordingActor
    private func startStreamingUpdates() async {
        var cancellables = Set<AnyCancellable>()
        startLocationUpdates().eraseToAnyCancellable().store(in: &cancellables)
        startStatusUpdates().eraseToAnyCancellable().store(in: &cancellables)
        await MainActor.run { self.cancellables = cancellables }
        logger.info("Started streaming updates.")
    }
    
    @RecordingActor
    private func startLocationUpdates() -> Task<Void, Never> {
        let locationStream = Perceptions { [locationService] in locationService.location }
        return Task { [weak self, locationStream] in
            for await location in locationStream where !Task.isCancelled {
                guard let self else { return }
                do {
                    let (sample, pause) = try await state.processLocation(location, with: altitudeService?.altitude)
                    guard let identifier = state.workoutIdentifier else { return }
                    if let sample {
                        try await database.addRouteSample(
                            sample,
                            toWorkoutWith: identifier,
                            updatedDistance: state.distance,
                            updatedEnergy: state.energy,
                            updatedRepetitions: stepService?.stepCount
                        )
                    }
                    if let pause {
                        try await database.addPause(pause, toWorkoutWith: identifier)
                    }
                } catch {
                    logger.error("Failed to process location: \((error as CustomDebugStringConvertible).debugDescription).")
                }
            }
        }
    }
    
    @RecordingActor
    private func startStatusUpdates() -> Task<Void, Never> {
        let statusStream = Perceptions { [state] in state.status }
        return Task { [weak self, statusStream] in
            for await status in statusStream where !Task.isCancelled {
                guard let self else { return }
                locationService.changeMode(to: status.isCollectingData ? .recording : .idle)
                altitudeService?.changeShouldRecord(status.isCollectingData)
                stepService?.changeShouldRecord(status.isCollectingData, lastStartDate: state.lastStartDate)
                await MainActor.run { self.status = status }
            }
        }
    }
    
    @RecordingActor
    private func checkStartingConditions() throws(WorkoutRecorderError) {
        guard locationService.status.locationAuthorizationSufficient else { throw WorkoutRecorderError.locationAuthorizationInsufficient }
        guard state.status == .idle else { throw WorkoutRecorderError.alreadyRecording }
    }
    
    // MARK: Public API
    
    /// Starts the recording process for a workout.
    /// - throws: This method fails if this class has not been initialized or is currently in a failed or recording state.
    @RecordingActor
    public func startRecording() async throws {
        do {
            try checkStartingConditions()
            let date: Date = .now
            let workout = try await database.initializeWorkout(with: state.workoutType, startDate: date)
            try await state.startOrContinue(workout, on: date)
            logger.info("Started recording of a new workout.")
        } catch {
            logger.error("Failed to start recording of a new workout: \((error as CustomDebugStringConvertible).debugDescription).")
            throw error
        }
    }
    
    /// Continues the recording process for a workout that has previously been ended.
    @RecordingActor
    public func continueRecording(with identifier: UUID) async throws {
        do {
            try checkStartingConditions()
            let date: Date = .now
            let workout = try await database.continueWorkout(with: identifier, continueDate: date)
            try await state.startOrContinue(workout, on: date)
            logger.info("Continued recording of workout with identifier \(identifier).")
        } catch {
            logger.error("Failed to contnue recording: \((error as CustomDebugStringConvertible).debugDescription).")
            throw error
        }
    }
    
    /// Pauses the recording process to be resumed in the near future.
    /// - throws: If the transition to a
    /// - note: Data will be collected even while paused, but ignored in the statistic calculation.
    @RecordingActor
    public func pauseRecording() async throws {
        do {
            guard let identifier = state.workoutIdentifier else { throw WorkoutRecorderError.notRecording }
            if let pause = try state.pause(on: .now) {
                try await database.addPause(pause, toWorkoutWith: identifier)
            }
            logger.info("Paused active workout recording.")
        } catch {
            logger.error("Failed to pause active workout recording: \((error as CustomDebugStringConvertible).debugDescription).")
            throw error
        }
    }
    
    /// Resumes the recording process after being paused through ``pauseRecording()``.
    @RecordingActor
    public func resumeRecording() async throws {
        do {
            guard let identifier = state.workoutIdentifier else { throw WorkoutRecorderError.notRecording }
            if let pause = try state.resume(on: .now) {
                try await database.addPause(pause, toWorkoutWith: identifier)
            }
            logger.info("Resumed active workout recording.")
        } catch {
            logger.error("Failed to resume active workout recording: \((error as CustomDebugStringConvertible).debugDescription).")
            throw error
        }
    }
    
    /// Ends the recording process and resets the workout recorder for the next recording.
    /// - returns: The finalized recorded workout if data was collected, `nil` otherwise.
    /// - throws: If this class is currently not recording a workout.
    @RecordingActor
    public func endRecording() async throws -> RawWorkout? {
        do {
            guard let identifier = state.workoutIdentifier else { throw WorkoutRecorderError.notRecording }
            let date: Date = .now
            if let pause = try state.end(on: date) {
                try await database.addPause(pause, toWorkoutWith: identifier)
            }
            let workout = try await database.finalizeWorkout(with: identifier, endDate: date)
            if workout == nil {
                logger.info("Ended workout recording and discarded data.")
            } else {
                logger.info("Ended workout recording for workout with identifier \(identifier).")
            }
            return workout
        } catch {
            logger.error("Failed to end workout recording: \((error as CustomDebugStringConvertible).debugDescription).")
            throw error
        }
    }
}
