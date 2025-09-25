import Combine
import CoreLocation
import Foundation
import OSLog
import Perception

/// A class for recording and monitoring the progress of a workout.
/// - warning: Before this class can be used make sure to gather user authorization for at least location data and optionally altitude and
/// step data.
@Observable
@MainActor
public class WorkoutRecorder {
    
    public typealias Status = WorkoutRecorderStatus
    
    private let logger = Logger(category: "WorkoutRecorder")
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private let state: WorkoutRecorderState
    private let database: Database
    private let locationService: LocationService
    private let altitudeService: AltitudeService?
    private let stepService: StepService?
    /// The permission requirements based on the configuration provided to the OutRunCore on initialization.
    public let neededPermissions: Set<WorkoutRecorderPermission>
    
    public private(set) var status: Status
    public private(set) var workoutType: WorkoutType
    public private(set) var distance: Measurement<UnitLength>
    public private(set) var duration: DynamicTimeInterval
    public private(set) var energy: Measurement<UnitEnergy>
    public private(set) var speed: Measurement<UnitSpeed>
    /// The permissions missing for an ideal recording experience. Check each elements ``WorkoutRecorderPermissionRequirement/isRequired``
    /// to determine which permissions must be aquired before a recording can be started.
    public private(set) var missingPermissions: Set<WorkoutRecorderPermission>
    /// Indicates the data types that are currently not recorded due to an internal failure. This information should be communicated to the
    /// user together with the recommendation to restart the app.
    public private(set) var failedDataTypeCollection: [RecordableDataTypes:Error]
    
    init(
        user: RawUser,
        database: Database,
        locationService: LocationService,
        altitudeService: AltitudeService?,
        stepService: StepService?
    ) async {
        
        self.state = await .init(user: user)
        self.database = database
        self.locationService = locationService
        self.altitudeService = altitudeService
        self.stepService = stepService
        self.neededPermissions = Set([.location, altitudeService != nil || stepService != nil ? .motionAndFitness : nil].compactMap { $0 })
        
        self.status = await state.status
        self.workoutType = await state.workoutType
        self.distance = await state.distanceMeasurement
        self.duration = await state.activeDuration
        self.energy = await state.energyMeasurement
        self.speed = await state.speedMeasurement
        let locationAuthorizationSufficient = locationService.status.authorizationSufficient
        let altitudeAuthorizationSufficient = await altitudeService?.status.authorizationSufficient ?? true
        let stepAuthorizationSufficient = await stepService?.status.authorizationSufficient ?? true
        let motionAndFitnessAuthorizationSufficient = altitudeAuthorizationSufficient && stepAuthorizationSufficient
        self.missingPermissions = Set(neededPermissions.compactMap { requirement in
            switch requirement {
            case .location: locationAuthorizationSufficient ? nil : requirement
            case .motionAndFitness: motionAndFitnessAuthorizationSufficient ? nil : requirement
            }
        }.compactMap { $0 })
        self.failedDataTypeCollection = [:]
        await startStreamingRecordingActorUpdates()
        startStreamingMainActorUpdates()
        
        do {
            try await state.signalSuccessfulInitialization()
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
    
    @BackgroundActor
    private func startStreamingRecordingActorUpdates() async {
        var cancellables = Set<AnyCancellable>()
        startUserUpdates().eraseToAnyCancellable().store(in: &cancellables)
        startFitnessServicesStatusUpdates()?.eraseToAnyCancellable().store(in: &cancellables)
        startStateStatusUpdates().eraseToAnyCancellable().store(in: &cancellables)
        startStatePropertyUpdates(of: \.workoutType) { $0.workoutType = $1 }.eraseToAnyCancellable().store(in: &cancellables)
        startStatePropertyUpdates(of: \.distanceMeasurement) { $0.distance = $1 }.eraseToAnyCancellable().store(in: &cancellables)
        startStatePropertyUpdates(of: \.activeDuration) { $0.duration = $1 }.eraseToAnyCancellable().store(in: &cancellables)
        startStatePropertyUpdates(of: \.energyMeasurement) { $0.energy = $1 }.eraseToAnyCancellable().store(in: &cancellables)
        startStatePropertyUpdates(of: \.speedMeasurement) { $0.speed = $1 }.eraseToAnyCancellable().store(in: &cancellables)
        await MainActor.run { self.cancellables = cancellables }
    }
    
    private func startStreamingMainActorUpdates() {
        startLocationUpdates().eraseToAnyCancellable().store(in: &cancellables)
        startLocationServiceStatusUpdates().eraseToAnyCancellable().store(in: &cancellables)
    }
    
    @BackgroundActor
    private func startUserUpdates() -> Task<Void, Never> {
        Task { [logger, weak self] in
            let (userStream, task): (AsyncThrowingStream<RawUser?, Error>, Task<Void, Never>)
            do {
                guard let database = self?.database else { throw WorkoutRecorderError.notInitialized }
                (userStream, task) = try await database.userStream()
            } catch {
                logger.fault("Could not start streaming user updates: \((error as CustomDebugStringConvertible).debugDescription)")
                return
            }
            do {
                for try await user in userStream where !Task.isCancelled {
                    guard let self, let user else { return }
                    state.update(basedOn: user)
                }
            } catch {
                logger.fault("User update streaming failed: \((error as CustomDebugStringConvertible).debugDescription)")
            }
            task.cancel()
        }
    }
    
    private func startLocationUpdates() -> Task<Void, Never> {
        let locationStream = Perceptions { [locationService] in locationService.location }
        return Task { [weak self] in
            for await location in locationStream where !Task.isCancelled {
                guard let self else { return }
                do {
                    let (sample, pause) = try await state.processLocation(location, with: altitudeService?.altitude)
                    guard let identifier = await state.workoutIdentifier else { continue }
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
    
    private func startLocationServiceStatusUpdates() -> Task<Void, Never> {
        let statusStream = Perceptions { [locationService] in locationService.status }
        return Task { [weak self] in
            for await status in statusStream where !Task.isCancelled {
                guard let self else { return }
                if status.authorizationSufficient {
                    await MainActor.run { _ = missingPermissions.remove(.location) }
                } else {
                    await MainActor.run { _ = missingPermissions.insert(.location) }
                }
                if case .failed(let error) = status {
                    await MainActor.run { failedDataTypeCollection[.location] = error }
                }
            }
        }
    }
    
    @BackgroundActor
    private func startFitnessServicesStatusUpdates() -> Task<Void, Never>? {
        guard altitudeService != nil || stepService != nil else { return nil }
        let statusStream = Perceptions { [altitudeService, stepService] in (altitudeService?.status, stepService?.status) }
        return Task { [weak self] in
            for await (altitudeServiceStatus, stepServiceStatus) in statusStream where !Task.isCancelled {
                guard let self else { return }
                if altitudeServiceStatus?.authorizationSufficient ?? true && stepServiceStatus?.authorizationSufficient ?? true {
                    await MainActor.run { _ = missingPermissions.remove(.motionAndFitness) }
                } else {
                    await MainActor.run { _ = missingPermissions.insert(.motionAndFitness) }
                }
                if let altitudeServiceStatus, case .failed(let error) = altitudeServiceStatus {
                    await MainActor.run { failedDataTypeCollection[.preciseAltitude] = error }
                }
                if let stepServiceStatus, case .failed(let error) = stepServiceStatus {
                    await MainActor.run { failedDataTypeCollection[.steps] = error }
                }
            }
        }
    }
    
    @BackgroundActor
    private func startStateStatusUpdates() -> Task<Void, Never> {
        let statusStream = Perceptions { [state] in state.status }
        return Task { [weak self] in
            for await status in statusStream where !Task.isCancelled {
                guard let self else { return }
                altitudeService?.changeShouldRecord(status.isCollectingData)
                stepService?.changeShouldRecord(status.isCollectingData, lastStartDate: state.lastStartDate)
                await MainActor.run {
                    locationService.changeMode(to: status.isCollectingData ? .recording : .idle)
                    self.status = status
                }
            }
        }
    }
    
    @BackgroundActor
    private func startStatePropertyUpdates<T: Sendable>(
        of propertyKeyPath: KeyPath<WorkoutRecorderState, T>,
        updateClosure: @MainActor @escaping (WorkoutRecorder, T) -> Void
    ) -> Task<Void, Never> {
        let propertyStream = Perceptions { [state] in state[keyPath: propertyKeyPath] }
        return Task { [weak self] in
            for await property in propertyStream where !Task.isCancelled {
                guard var self else { return }
                await updateClosure(self, property)
            }
        }
    }
    
    @BackgroundActor
    private func checkStartingConditions() async throws(WorkoutRecorderError) {
        let locationAuthorizationSufficient = await MainActor.run { locationService.status.authorizationSufficient }
        guard locationAuthorizationSufficient else { throw WorkoutRecorderError.locationAuthorizationInsufficient }
        guard state.status == .idle else { throw WorkoutRecorderError.alreadyRecording }
    }
    
    // MARK: Public API
    
    /// Starts the recording process for a workout.
    /// - throws: This method fails if this class has not been initialized or is currently in a failed or recording state.
    @BackgroundActor
    public func startRecording() async throws {
        do {
            try await checkStartingConditions()
            let date: Date = .now
            let workout = try await database.initializeWorkout(with: state.workoutType, startDate: date)
            try state.startOrContinue(workout, on: date)
            logger.info("Started recording of a new workout.")
        } catch {
            logger.error("Failed to start recording of a new workout: \((error as CustomDebugStringConvertible).debugDescription).")
            throw error
        }
    }
    
    /// Continues the recording process for a workout that has previously been ended.
    @BackgroundActor
    public func continueRecording(with identifier: UUID) async throws {
        do {
            try await checkStartingConditions()
            let date: Date = .now
            let workout = try await database.continueWorkout(with: identifier, continueDate: date)
            try state.startOrContinue(workout, on: date)
            logger.info("Continued recording of workout with identifier \(identifier).")
        } catch {
            logger.error("Failed to contnue recording: \((error as CustomDebugStringConvertible).debugDescription).")
            throw error
        }
    }
    
    /// Pauses the recording process to be resumed in the near future.
    /// - throws: If the transition to a
    /// - note: Data will be collected even while paused, but ignored in the statistic calculation.
    @BackgroundActor
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
    @BackgroundActor
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
    @BackgroundActor
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
    
    /// Requests the specified permission if not already sufficiently granted.
    /// - throws: Throws if the permission cannot be requested. The error thrown should be displayed to the user together with the option to
    /// open the iOS app settings at ``UIApplication.openSettingsURLString`` by using ``UIApplication/open()``.
    @BackgroundActor
    public func requestAuthorization(for permission: WorkoutRecorderPermission) async throws {
        guard neededPermissions.contains(permission) else { return }
        switch permission {
        case .location:
            try await MainActor.run { try locationService.requestAuthorization() }
        case .motionAndFitness:
            try await altitudeService?.requestAuthorization()
            try await stepService?.requestAuthorization()
        }
        logger.info("Requested authorization for \(permission.debugDescription).")
    }
    
    /// Changes the workout type recorded by this class.
    /// - throws: Throws if a workout is currently running and modifying it in the database fails.
    @BackgroundActor
    public func changeWorkoutType(to type: WorkoutType) async throws {
        let oldType = state.workoutType
        state.changeWorkoutType(to: type)
        guard let identifier = state.workoutIdentifier else { return }
        do {
            try await database.changeWorkoutType(ofWorkoutWith: identifier, to: type, updatedEnergy: state.energy)
            logger.info("Changed type of workout with identifier \(identifier) to \(type.debugDescription).")
        } catch {
            state.changeWorkoutType(to: oldType)
            let description = (error as CustomDebugStringConvertible).debugDescription
            logger.error("Failed to update type of workout with identifier \(identifier) to \(type.debugDescription): \(description).")
        }
    }
}
