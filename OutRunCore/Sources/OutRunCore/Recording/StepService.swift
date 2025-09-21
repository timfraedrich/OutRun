import CoreMotion
import Foundation
import OSLog

/// A class gathering step data.
/// - warning: To use this service you must include the `NSMotionUsageDescription` key in your app’s Info.plist file and provide a usage
/// description string for this key.
@Observable
@BackgroundActor
class StepService {
    
    static nonisolated var stepsAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }
        
    private let logger = Logger(category: "StepService")
    private let pedometer = CMPedometer()
    
    var status: Status = .initializing
    var stepCount: Int? = nil
    
    init() {
        guard Self.stepsAvailable else {
            status = .failed(StepServiceError.stepsNotAvailable)
            logger.error("Steps not available.")
            return
        }
        updateStatus()
        logger.info("Initialized with steps available: \(Self.stepsAvailable)")
    }
    
    /// Requests authorization to access motion and fitness data if authorization has not been granted or denied already.
    func requestAuthorization() async throws {
        updateStatus()
        if status == .missingAuthorization {
            await CoreMotionHelper.requestMotionAndFitnessAuthorization()
            updateStatus()
        }
        switch status {
        case .idle, .updatingSince: return
        case .missingAuthorization: throw StepServiceError.authorizationMissing
        case .deniedAuthorization: throw StepServiceError.authorizationDenied
        case .restrictedAuthorization: throw StepServiceError.authorizationRestricted
        case .initializing: throw StepServiceError.unknownAuthorizationStatus
        case .failed(let error): throw error
        }
    }
    
    /// Change whether the service should collect step data.
    func changeShouldRecord(_ shouldRecord: Bool, lastStartDate: Date?) {
        if shouldRecord, !status.isCollectingData, let lastStartDate {
            start(from: lastStartDate)
        } else if !shouldRecord, status.isCollectingData {
            reset()
        }
    }
    
    /// Starts step data collection from the given date.
    /// - warning: Calling this method while step data is being collected will perform a restart of the data collection and update the
    /// ``status`` accordingly.
    private func start(from date: Date) {
        updateStatus()
        switch status {
        case .idle:
            break
        case .failed:
            logger.error("Tried to start step data collection in failed state.")
            return
        case .updatingSince:
            logger.fault("Started step data collection while already collecting, triggering a reset.")
            reset()
        case .missingAuthorization, .deniedAuthorization, .restrictedAuthorization:
            logger.error("Tried to start step data collection with insufficient authorization")
            return
        case .initializing:
            logger.error("Tried to start step data collection before initialization was complete.")
            return
        }
        status = .updatingSince(.now)
        pedometer.startUpdates(from: date) { [weak self] data, error in
            guard let self else { return }
            if let data {
                stepCount = data.numberOfSteps.intValue
            } else if let error {
                reset()
                status = .failed(error)
            }
        }
    }
    
    /// Stops step data collection and resets this class.
    private func reset() {
        updateStatus()
        if case .updatingSince = status {
            pedometer.stopUpdates()
            status = .idle
        }
        stepCount = nil
        logger.info("Reset step service and stopped step data collection.")
    }
    
    private func updateStatus() {
        let newStatus: Status = switch CMPedometer.authorizationStatus() {
        case .authorized:
            if case .updatingSince(let date) = status {
                .updatingSince(date)
            } else {
                .idle
            }
        case .notDetermined: .missingAuthorization
        case .denied: .deniedAuthorization
        case .restricted: .restrictedAuthorization
        @unknown default: .failed(StepServiceError.unknownAuthorizationStatus)
        }
        status = newStatus
        logger.info("Updated status to: \(self.status.debugDescription)")
    }
    
    // MARK: - Status
    
    enum Status: CustomDebugStringConvertible, Equatable {
        
        /// Preparing functionality.
        case initializing
        /// Cannot receive step data due to missing authorization.
        /// Request authorization from the user by calling ``StepService/requestAuthorization()``.
        case missingAuthorization
        /// Cannot receive step data due to system settings. Prompt the user to change this in the Settings app under
        /// `Privacy & Security > Motion & Fitness`
        case restrictedAuthorization
        /// Cannot receive step data due to denied authorization. Prompt the user to change this in the Settings app.
        /// Settings can be opened by using ``UIApplication/open()`` to open ``UIApplication.openSettingsURLString``.
        case deniedAuthorization
        /// Ready to collect step data. Call ``StepService/start()`` to start.
        case idle
        /// Currently receiving step data updates. Refer to the mode to determine which kind.
        case updatingSince(Date)
        /// Failed with the specified error.
        case failed(Error)
        
        /// Indicates whether sufficient permission to record step data was granted by the user.
        var authorizationSufficient: Bool {
            switch self {
            case .missingAuthorization, .restrictedAuthorization, .deniedAuthorization: false
            default: true
            }
        }
        
        var isCollectingData: Bool {
            if case .updatingSince = self { true } else { false }
        }
        
        var debugDescription: String {
            switch self {
            case .initializing: ".initializing"
            case .missingAuthorization: ".missingAuthorization"
            case .restrictedAuthorization: ".restrictedAuthorization"
            case .deniedAuthorization: ".deniedAuthorization"
            case .idle: ".idle"
            case .updatingSince(let date): ".updatingSince(\(date.formatted(.iso8601)))"
            case .failed(let error): ".failed(\((error as CustomDebugStringConvertible).debugDescription)"
            }
        }
        
        static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.initializing, .initializing),
                (.missingAuthorization, .missingAuthorization),
                (.restrictedAuthorization, .restrictedAuthorization),
                (.deniedAuthorization, .deniedAuthorization),
                (.idle, .idle),
                (.failed, .failed):
                true
            case (.updatingSince(let lhsDate), .updatingSince(let rhsDate)):
                lhsDate == rhsDate
            default: false
            }
        }
    }
    
    // MARK: - StepServiceError
    
    enum StepServiceError: LocalizedError, CustomDebugStringConvertible {
        
        case stepsNotAvailable
        case authorizationMissing
        case authorizationDenied
        case authorizationRestricted
        case unknownAuthorizationStatus
        
        var debugDescription: String {
            switch self {
            case .stepsNotAvailable: ".stepsNotAvailable"
            case .authorizationMissing: ".authorizationMissing"
            case .authorizationDenied: ".authorizationDenied"
            case .authorizationRestricted: ".authorizationRestricted"
            case .unknownAuthorizationStatus: ".unknownAuthorizationStatus"
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .stepsNotAvailable: R.string.localizable.step_service_error_steps_not_available()
            case .authorizationMissing: R.string.localizable.step_service_error_authorization_missing()
            case .authorizationDenied: R.string.localizable.step_service_error_authorization_denied()
            case .authorizationRestricted: R.string.localizable.step_service_error_authorization_restricted()
            case .unknownAuthorizationStatus: R.string.localizable.step_service_error_unknown_authorization_status()
            }
        }
    }
}
