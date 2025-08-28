import Combine
import CoreLocation
import Foundation
import OSLog

/// A class managing authorization to and the gathering of location updates.
public class LocationService: NSObject {
    
    private let logger = Logger(category: "LocationService")
    private let locationManager = CLLocationManager()
    private let statusSubject = CurrentValueSubject<Status, Never>(.initializing)
    private let modeSubject: CurrentValueSubject<Mode, Never>
    private let lastLocationSubject = CurrentValueSubject<CLLocation?, Never>(nil)
    
    public var status: Status { statusSubject.value }
    public var statusPublisher: some Publisher<Status, Never> { statusSubject.eraseToAnyPublisher() }
    public var mode: Mode { modeSubject.value }
    public var modePublisher: some Publisher<Mode, Never> { modeSubject.eraseToAnyPublisher() }
    public var lastLocation: CLLocation? { lastLocationSubject.value }
    public var lastLocationPublisher: some Publisher<CLLocation?, Never> { lastLocationSubject.eraseToAnyPublisher() }
    
    init(mode: Mode = .idle) {
        self.modeSubject = .init(mode)
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = mode.allowsBackgroundLocationUpdates
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        // manual override as changeStatus function would (and should) reject updates during initialization
        statusSubject.send(Self.status(for: locationManager.authorizationStatus, locationManager.accuracyAuthorization, and: mode))
        logger.info("Location service initialized with status \(self.status.debugDescription).")
        if status.isReceivingLocations {
            locationManager.startUpdatingLocation()
            logger.info("Location updates were requested after initialization.")
        }
    }
    
    private func changeStatus(to status: Status) {
        guard self.status.canTransition, self.status != status else { return }
        let oldStatus = self.status
        statusSubject.send(status)
        logger.info("Location service status changed to \(status.debugDescription).")
        if !oldStatus.isReceivingLocations && status.isReceivingLocations {
            locationManager.startUpdatingLocation()
            logger.info("Location updates were requested.")
        } else if oldStatus.isReceivingLocations && !status.isReceivingLocations {
            locationManager.stopUpdatingLocation()
            logger.info("Stop of location updates was requested.")
        }
        if case .failed(let error) = status {
            logger.critical("Location service failed with error: \((error as CustomDebugStringConvertible).debugDescription)")
        }
    }
    
    private static func status(for authStatus: CLAuthorizationStatus, _ accuracy: CLAccuracyAuthorization, and mode: Mode) -> Status {
        if authStatus.isAuthorized, accuracy == .fullAccuracy {
            mode.correspondingStatus
        } else if authStatus.isAuthorized {
            .restrictedAuthorization
        } else if authStatus.isDenied {
            .deniedAuthorization
        } else {
            .missingAuthorization
        }
    }
    
    public func changeMode(to mode: Mode) {
        guard self.mode != mode else { return }
        logger.info("Changing mode to \(mode.debugDescription).")
        self.modeSubject.send(mode)
        locationManager.allowsBackgroundLocationUpdates = mode.allowsBackgroundLocationUpdates
        changeStatus(to: mode.correspondingStatus)
    }
    
    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
        logger.info("Location authorization was requested.")
    }
    
    // MARK: - Mode
    
    public enum Mode: CustomDebugStringConvertible, Equatable {
        
        /// Receive location updates while the app is in the foreground.
        case idle
        /// Receive accurate locations even while the app is in the background.
        case recording
        
        /// Indicating whether the location service should receive locations in the background while in this mode.
        fileprivate var allowsBackgroundLocationUpdates: Bool {
            switch self {
            case .idle: false
            case .recording: true
            }
        }
        
        fileprivate var correspondingStatus: Status {
            switch self {
            case .idle: .idle
            case .recording: .recording
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .idle: ".idle"
            case .recording: ".recording"
            }
        }
    }
    
    // MARK: - Status
    
    public enum Status: CustomDebugStringConvertible, Equatable {
        
        /// Preparing functionality.
        case initializing
        /// Cannot receive location updates due to missing authorization.
        /// Request authorization from the user by calling ``LocationService/requestAuthorization()``.
        case missingAuthorization
        /// Cannot receive accurate location updates due to insufficient authorization. Prompt the user to change this in the Settings app.
        /// Settings can be opened by using ``UIApplication/open()`` to open ``UIApplication.openSettingsURLString``.
        case restrictedAuthorization
        /// Cannot receive location updates due to denied authorization. Prompt the user to change this in the Settings app.
        /// Settings can be opened by using ``UIApplication/open()`` to open ``UIApplication.openSettingsURLString``.
        case deniedAuthorization
        /// Receiving location updates while in foreground.
        case idle
        /// Receiving accurate locations in foreground and background.
        case recording
        /// Failed with the specified error. The error should be presented to the user and the app will have to be restarted to restore
        /// functionality.
        case failed(Error)
        
        /// Indicating whether a transition to another status is allowed.
        fileprivate var canTransition: Bool {
            return switch self {
            case .failed, .initializing: false
            default: true
            }
        }
        
        /// Indicates whether the service should currently receive location updates.
        /// - note: This does not guaranteed that the service is actually receiving such updates.
        public var isReceivingLocations: Bool {
            switch self {
            case .idle, .recording: true
            default: false
            }
        }
        
        /// Indicates whether sufficient permission to record location data was granted by the user.
        public var locationAuthorizationSufficient: Bool {
            switch self {
            case .missingAuthorization, .restrictedAuthorization, .deniedAuthorization: false
            default: true
            }
        }
        
        public var debugDescription: String {
            switch self {
            case .initializing: ".initializing"
            case .missingAuthorization: ".missingAuthorization"
            case .restrictedAuthorization: ".restrictedAuthorization"
            case .deniedAuthorization: ".deniedAuthorization"
            case .idle: ".idle"
            case .recording: ".recording"
            case .failed(let error): ".failed(\((error as CustomDebugStringConvertible).debugDescription)"
            }
        }
        
        public static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.initializing, .initializing),
                (.missingAuthorization, .missingAuthorization),
                (.restrictedAuthorization, .restrictedAuthorization),
                (.deniedAuthorization, .deniedAuthorization),
                (.idle, .idle),
                (.recording, .recording),
                (.failed, .failed):
                true
            default:
                false
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            lastLocationSubject.send(location)
        }
    }
        
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        switch (error as? CLError)?.code {
        case .locationUnknown, .network, .denied:
            logger.error("A temporary error was encountered: \(error.localizedDescription).")
        default:
            self.changeStatus(to: .failed(error))
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        logger.info("Location authorization status updated to \(status.debugDescription)")
        changeStatus(to: Self.status(for: status, manager.accuracyAuthorization, and: mode))
    }
}
