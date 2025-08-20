import Combine
import CoreMotion
import Foundation
import RswiftResources
import OSLog

/// A class gathering altitude updates.
/// - note: While an approximate altitude is received with the users location, this class allows for refinement of location samples.
/// - warning: To use this service you must include the `NSMotionUsageDescription` key in your app’s Info.plist file and provide a usage
/// description string for this key.
class AltitudeService {
    
    private let logger = Logger(category: "AltitudeService")
    private let operationQueue = OperationQueue()
    private let altimeter = CMAltimeter()
    private let statusSubject = CurrentValueSubject<Status, Never>(.initializing)
    private let lastAltitudeSubject = CurrentValueSubject<AltitudeSample?, Never>(nil)
    let mode: Mode
    
    var status: Status { statusSubject.value }
    var statusPublisher: some Publisher<Status, Never> { statusSubject.eraseToAnyPublisher() }
    var lastAltitude: AltitudeSample? { lastAltitudeSubject.value }
    var lastAltitudePublisher: some Publisher<AltitudeSample?, Never> { lastAltitudeSubject.eraseToAnyPublisher() }
    
    init() {
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInitiated
        mode = if CMAltimeter.isAbsoluteAltitudeAvailable() {
            .absoluteAltitudeAvailable
        } else if CMAltimeter.isRelativeAltitudeAvailable() {
            .relativeAltitudeAvailable
        } else {
            .noAlitudeAvailable
        }
        guard mode != .noAlitudeAvailable else {
            statusSubject.send(.failed(AltitudeServiceError.altitudeNotAvailable))
            logger.error("Altitude not available.")
            return
        }
        updateStatus()
        logger.info("Initialized with mode: \(self.mode.debugDescription)")
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
        case .missingAuthorization: throw AltitudeServiceError.authorizationMissing
        case .deniedAuthorization: throw AltitudeServiceError.authorizationDenied
        case .restrictedAuthorization: throw AltitudeServiceError.authorizationRestricted
        case .initializing: throw AltitudeServiceError.unknownAuthorizationStatus
        case .failed(let error): throw error
        }
    }
    
    /// Starts altitude updates.
    /// - warning: Calling this method while altitude data is being collected will perform a restart of the data collection and update the
    /// ``status`` accordingly.
    func start() {
        updateStatus()
        switch status {
        case .idle:
            break
        case .failed:
            logger.error("Tried to start altitude updates in failed state.")
            return
        case .updatingSince:
            logger.fault("Started altitude updates while already updating, triggering a reset.")
            reset()
        case .missingAuthorization, .deniedAuthorization, .restrictedAuthorization:
            logger.error("Tried to start altitude updates with insufficient authorization")
            return
        case .initializing:
            logger.error("Tried to start altitude updates before initialization was complete.")
            return
        }
        statusSubject.send(.updatingSince(.now))
        switch mode {
        case .absoluteAltitudeAvailable:
            altimeter.startAbsoluteAltitudeUpdates(to: operationQueue) { [weak self] altitudeData, error in
                guard let self else { return }
                if let altitudeData {
                    lastAltitudeSubject.send(.init(isAbsolute: true, timestamp: .now, altitude: altitudeData.altitude))
                } else if let error {
                    reset()
                    statusSubject.send(.failed(error))
                }
            }
            logger.info("Started absolute altitude updates.")
        case .relativeAltitudeAvailable:
            altimeter.startRelativeAltitudeUpdates(to: operationQueue) { [weak self] altitudeData, error in
                guard let self else { return }
                if let altitudeData {
                    lastAltitudeSubject.send(.init(isAbsolute: false, timestamp: .now, altitude: altitudeData.relativeAltitude.doubleValue))
                } else if let error {
                    reset()
                    statusSubject.send(.failed(error))
                }
            }
            logger.info("Started relative altitude updates.")
        case .noAlitudeAvailable:
            logger.info("Altitude updates are not supported on this device.")
        }
    }
    
    /// Stops altitude updates and resets this class.
    func reset() {
        updateStatus()
        if case .updatingSince = status {
            switch mode {
            case .absoluteAltitudeAvailable: altimeter.stopAbsoluteAltitudeUpdates()
            case .relativeAltitudeAvailable: altimeter.stopRelativeAltitudeUpdates()
            case .noAlitudeAvailable: break
            }
            statusSubject.send(.idle)
        }
        lastAltitudeSubject.send(nil)
        logger.info("Reset altitude service and stopped altitude updates.")
    }
    
    private func updateStatus() {
        let newStatus: Status = switch CMAltimeter.authorizationStatus() {
        case .authorized:
            if case .updatingSince(let date) = status {
                .updatingSince(date)
            } else {
                .idle
            }
        case .notDetermined: .missingAuthorization
        case .denied: .deniedAuthorization
        case .restricted: .restrictedAuthorization
        @unknown default: .failed(AltitudeServiceError.unknownAuthorizationStatus)
        }
        statusSubject.send(newStatus)
        logger.info("Updated status to: \(self.status.debugDescription)")
    }
    
    // MARK: - AltitudeSample
    
    struct AltitudeSample {
        
        /// Indicates whether the ``altitude`` variable describes an absolute value or relative change to the start date.
        let isAbsolute: Bool
        /// The timestamp at which the altitude was recorded.
        let timestamp: Date
        /// The relative value of the altitude.
        let altitude: Double
    }
    
    // MARK: - Mode
    
    enum Mode: CustomDebugStringConvertible, Equatable {
        
        /// Altitude changes cannot be observed, use location data as a fallback.
        case noAlitudeAvailable
        /// Only relative altitude changes can be observed upon request, use this data in conjunction with a start value gathered or
        /// computed from location data.
        case relativeAltitudeAvailable
        /// Absolute altitude will be observed and published upon request.
        case absoluteAltitudeAvailable
        
        var altitudeAvailable: Bool {
            switch self {
            case .absoluteAltitudeAvailable, .relativeAltitudeAvailable: true
            case .noAlitudeAvailable: false
            }
        }
        
        var debugDescription: String {
            switch self {
            case .noAlitudeAvailable: ".noAlitudeAvailable"
            case .relativeAltitudeAvailable: ".relativeAltitudeAvailable"
            case .absoluteAltitudeAvailable: ".absoluteAltitudeAvailable"
            }
        }
    }
    
    // MARK: - Status
    
    enum Status: CustomDebugStringConvertible, Equatable {
        
        /// Preparing functionality.
        case initializing
        /// Cannot receive altitude updates due to missing authorization.
        /// Request authorization from the user by calling ``AltitudeService/requestAuthorization()``.
        case missingAuthorization
        /// Cannot receive altitude updates due to system settings. Prompt the user to change this in the Settings app under
        /// `Privacy & Security > Motion & Fitness`
        case restrictedAuthorization
        /// Cannot receive altitude updates due to denied authorization. Prompt the user to change this in the Settings app.
        /// Settings can be opened by using ``UIApplication/open()`` to open ``UIApplication.openSettingsURLString``.
        case deniedAuthorization
        /// Ready to collect altitude updates. Call ``AltitudeService/start()`` to start.
        case idle
        /// Currently receiving altitude updates. Refer to the mode to determine which kind.
        case updatingSince(Date)
        /// Failed with the specified error.
        case failed(Error)
        
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
    
    enum AltitudeServiceError: LocalizedError, CustomDebugStringConvertible {
        
        case altitudeNotAvailable
        case authorizationMissing
        case authorizationDenied
        case authorizationRestricted
        case unknownAuthorizationStatus
        
        var debugDescription: String {
            switch self {
            case .altitudeNotAvailable: ".altitudeNotAvailable"
            case .authorizationMissing: ".authorizationMissing"
            case .authorizationDenied: ".authorizationDenied"
            case .authorizationRestricted: ".authorizationRestricted"
            case .unknownAuthorizationStatus: ".unknownAuthorizationStatus"
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .altitudeNotAvailable: R.string.localizable.altitude_service_error_altitude_not_available()
            case .authorizationMissing: R.string.localizable.altitude_service_error_authorization_missing()
            case .authorizationDenied: R.string.localizable.altitude_service_error_authorization_denied()
            case .authorizationRestricted: R.string.localizable.altitude_service_error_authorization_restricted()
            case .unknownAuthorizationStatus: R.string.localizable.altitude_service_error_unknown_authorization_status()
            }
        }
    }
}
