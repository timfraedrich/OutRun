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
    private var workout: Workout?
    private var lastRecordedLocation: CLLocation?
    /// The absolute altitude of the first location for which relative altitude changes were used to refine the altitude measurement.
    private var baseAltitude: Double?
    private var stepCount: Int?
    
    public var status: Status { statusSubject.value }
    public var statusPublisher: some Publisher<Status, Never> { statusSubject.eraseToAnyPublisher() }
    
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
    public func startRecording() throws {
        do {
            try startOrContinueWorkout(nil)
            logger.info("Started recording workout.")
        } catch {
            logger.error("Failed to start recording workout.")
            throw error
        }
    }
    
    /// Continues the recording process for a workout.
    /// -
    public func continueRecording(_ workout: Workout) throws {
        try startOrContinueWorkout(workout)
    }
    
    // TODO: Add manual pause and resume functionality
    
    public func endRecording() throws(WorkoutRecorderError) -> Workout? {
        try checkStatus()
        guard case .recording = status, let workout else { throw .notRecording }
        reset()
        try changeStatus(to: .idle)
        if workout.distance > 0 {
            // TODO: finalize workout
            return workout
        } else {
            // TODO: delete workout
            return nil
        }
    }
    
    private func startOrContinueWorkout(_ workout: Workout?) throws(WorkoutRecorderError) {
        try checkStatus()
        try checkLocationAuthorization()
        guard case .idle = status else { throw .alreadyRecording }
        if let workout {
            workout
        } else {
            // TODO: initiate workout
        }
        try changeStatus(to: .recording)
    }
    
    private func checkStatus() throws(WorkoutRecorderError) {
        if case .failed = status {
            throw .inFailedState
        } else if case .initializing = status {
            throw .notInitialized
        }
    }
    
    private func changeStatus(to newStatus: Status) throws(WorkoutRecorderError) {
        guard newStatus != status else { return }
        try checkStatus()
        if case .initializing = newStatus {
            throw .invalidStatusTransition
        }
        statusSubject.send(newStatus)
    }
    
    private func checkLocationAuthorization() throws(WorkoutRecorderError) {
        if !locationService.status.locationAuthorizationSufficient {
            throw .locationAuthorizationInsufficient
        }
    }
    
    private func reset() {
        workout = nil
        lastRecordedLocation = nil
        baseAltitude = nil
        stepCount = nil
    }
    
    // MARK: Subscriptions
    
    private func prepareSubscriptions() {
        statusSubject.receive(on: processingQueue).sink(receiveValue: statusBinder).store(in: &cancellables)
        locationService.lastLocationPublisher.receive(on: processingQueue).sink(receiveValue: lastLocationBinder).store(in: &cancellables)
        stepService.stepCountPublisher.receive(on: processingQueue).sink(receiveValue: stepCountBinder).store(in: &cancellables)
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
                if status.isCollectingData, !stepService.status.isCollectingData, let workout {
                    stepService.start(from: workout.startDate)
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
                  let workout,
                  var location,
                  location.timestamp > lastRecordedLocation?.timestamp ?? .distantPast,
                  // TODO: Respect user selected location accuracy
                  location.horizontalAccuracy < 20
            else { return }
            // TODO: Add auto pause functionality
            let addedDistance: Double = if let lastRecordedLocation { location.distance(from: lastRecordedLocation) } else { .zero }
            let sample = WorkoutRouteDataSample(from: location, attachTo: workout)
            sample.altitude = Float(refineAltitude(location.altitude))
            // TODO: add location to database
            lastRecordedLocation = location
        }
    }
    
    private var stepCountBinder: (Int?) -> Void {
        { [weak self] stepCount in
            guard let self, let stepCount else { return }
            self.stepCount = stepCount
            // TODO: update value in database
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
    
    public enum WorkoutRecorderError: LocalizedError, Equatable {
        
        case alreadyRecording
        case inFailedState
        case notInitialized
        case notRecording
        case locationAuthorizationInsufficient
        case invalidStatusTransition
        
        // TODO: Add proper localization
        public var errorDescription: String? {
            switch self {
            default: ""
            }
        }
    }
    
    // MARK: - Status
    
    public enum Status: Equatable, CustomStringConvertible, CustomDebugStringConvertible {
        
        case initializing
        case idle
        case recording
        case paused(manual: Bool)
        case failed(Error)
        
        // TODO: Add proper localization
        public var description: String {
            switch self {
            case .initializing: ""
            case .idle: ""
            case .recording: ""
            case .paused(let manual): ""
            case .failed(_): ""
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .initializing: ".initializing"
            case .idle: ".idle"
            case .recording: ".recording"
            case .paused(manual: let manual): ".paused(manual: \(manual))"
            case .failed(let error): ".failed(\((error as NSError).debugDescription))"
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
