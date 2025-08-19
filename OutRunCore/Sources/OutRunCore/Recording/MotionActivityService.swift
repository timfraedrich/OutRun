import Combine
import CoreMotion
import Foundation
import RswiftResources
import OSLog

/// A class gathering motion activity updates.
/// - warning: To use this service you must include the `NSMotionUsageDescription` key in your app's Info.plist file and provide a usage
/// description string for this key.
class MotionActivityService {
    
    private let logger = Logger(category: "MotionActivityService")
    private let operationQueue = OperationQueue()
    private let motionActivityManager = CMMotionActivityManager()
    let activityAvailable: Bool
    private let statusSubject = CurrentValueSubject<Status, Never>(.initializing)
    private let lastActivitySubject = CurrentValueSubject<CMMotionActivity?, Never>(nil)
    
    var status: Status { statusSubject.value }
    var statusPublisher: some Publisher<Status, Never> { statusSubject.eraseToAnyPublisher() }
    var lastActivity: CMMotionActivity? { lastActivitySubject.value }
    var lastActivityPublisher: some Publisher<CMMotionActivity?, Never> { lastActivitySubject.eraseToAnyPublisher() }
    
    init() {
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInitiated
        activityAvailable = CMMotionActivityManager.isActivityAvailable()
        guard activityAvailable else {
            statusSubject.send(.failed(MotionActivityServiceError.activityNotAvailable))
            logger.error("Motion activity not available.")
            return
        }
        updateStatus()
        logger.info("Initialized with activity available: \(self.activityAvailable)")
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
        case .missingAuthorization: throw MotionActivityServiceError.authorizationMissing
        case .deniedAuthorization: throw MotionActivityServiceError.authorizationDenied
        case .restrictedAuthorization: throw MotionActivityServiceError.authorizationRestricted
        case .initializing: throw MotionActivityServiceError.unknownAuthorizationStatus
        case .failed(let error): throw error
        }
    }
    
    /// Starts motion activity updates.
    /// - warning: Calling this method while motion activity data is being collected will perform a restart of the data collection and update the
    /// ``status`` accordingly.
    func start() {
        updateStatus()
        switch status {
        case .idle:
            break
        case .failed:
            logger.error("Tried to start motion activity updates in failed state.")
            return
        case .updatingSince:
            logger.fault("Started motion activity updates while already updating, triggering a reset.")
            reset()
        case .missingAuthorization, .deniedAuthorization, .restrictedAuthorization:
            logger.error("Tried to start motion activity updates with insufficient authorization")
            return
        case .initializing:
            logger.error("Tried to start motion activity updates before initialization was complete.")
            return
        }
        statusSubject.send(.updatingSince(.now))
        motionActivityManager.startActivityUpdates(to: operationQueue) { [weak self] activity in
            guard let self else { return }
            if let activity {
                lastActivitySubject.send(activity)
            }
        }
        logger.info("Started motion activity updates.")
    }
    
    /// Stops motion activity updates and resets this class.
    func reset() {
        updateStatus()
        if case .updatingSince = status {
            motionActivityManager.stopActivityUpdates()
            statusSubject.send(.idle)
        }
        lastActivitySubject.send(nil)
        logger.info("Reset motion activity service and stopped activity updates.")
    }
    
    private func updateStatus() {
        let newStatus: Status = switch CMMotionActivityManager.authorizationStatus() {
        case .authorized:
            if case .updatingSince(let date) = status {
                .updatingSince(date)
            } else {
                .idle
            }
        case .notDetermined: .missingAuthorization
        case .denied: .deniedAuthorization
        case .restricted: .restrictedAuthorization
        @unknown default: .failed(MotionActivityServiceError.unknownAuthorizationStatus)
        }
        statusSubject.send(newStatus)
        logger.info("Updated status to: \(self.status.debugDescription)")
    }
    
    // MARK: - Status
    
    enum Status: CustomDebugStringConvertible, Equatable {
        
        /// Preparing functionality.
        case initializing
        /// Cannot receive motion activity updates due to missing authorization.
        /// Request authorization from the user by calling ``MotionActivityService/requestAuthorization()``.
        case missingAuthorization
        /// Cannot receive motion activity updates due to system settings. Prompt the user to change this in the Settings app under
        /// `Privacy & Security > Motion & Fitness`
        case restrictedAuthorization
        /// Cannot receive motion activity updates due to denied authorization. Prompt the user to change this in the Settings app.
        /// Settings can be opened by using ``UIApplication/open()`` to open ``UIApplication.openSettingsURLString``.
        case deniedAuthorization
        /// Ready to collect motion activity updates. Call ``MotionActivityService/start()`` to start.
        case idle
        /// Currently receiving motion activity updates.
        case updatingSince(Date)
        /// Failed with the specified error.
        case failed(Error)
        
        var debugDescription: String {
            switch self {
            case .initializing: ".initializing"
            case .missingAuthorization: ".missingAuthorization"
            case .restrictedAuthorization: ".restrictedAuthorization"
            case .deniedAuthorization: ".deniedAuthorization"
            case .idle: ".idle"
            case .updatingSince(let date): ".updatingSince(\(date.formatted(.iso8601)))"
            case .failed(let error): ".failed(\((error as NSError).debugDescription)"
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
    
    // MARK: - MotionActivityServiceError
    enum MotionActivityServiceError: LocalizedError, CustomDebugStringConvertible {
        
        case activityNotAvailable
        case authorizationMissing
        case authorizationDenied
        case authorizationRestricted
        case unknownAuthorizationStatus
        
        var debugDescription: String {
            switch self {
            case .activityNotAvailable: ".activityNotAvailable"
            case .authorizationMissing: ".authorizationMissing"
            case .authorizationDenied: ".authorizationDenied"
            case .authorizationRestricted: ".authorizationRestricted"
            case .unknownAuthorizationStatus: ".unknownAuthorizationStatus"
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .activityNotAvailable: R.string.localizable.motion_activity_service_error_activity_not_available()
            case .authorizationMissing: R.string.localizable.motion_activity_service_error_authorization_missing()
            case .authorizationDenied: R.string.localizable.motion_activity_service_error_authorization_denied()
            case .authorizationRestricted: R.string.localizable.motion_activity_service_error_authorization_restricted()
            case .unknownAuthorizationStatus: R.string.localizable.motion_activity_service_error_unknown_authorization_status()
            }
        }
    }
}
