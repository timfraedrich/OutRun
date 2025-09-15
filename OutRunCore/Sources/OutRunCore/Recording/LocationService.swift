import Combine
import CoreLocation
import Foundation
import OSLog

/// A class managing authorization to and the gathering of location updates.
/// - note: Location data is always available with correct authorization.
@Observable
@MainActor
class LocationService: NSObject, @MainActor CLLocationManagerDelegate {
    
    private let logger = Logger(category: "LocationService")
    private let locationManager: CLLocationManager
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []
    
    var status: Status = .initializing
    var mode: Mode
    var location: CLLocation?
    
    init(mode: Mode = .idle) async {
        self.mode = mode
        locationManager = .init()
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = mode.allowsBackgroundLocationUpdates
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.pausesLocationUpdatesAutomatically = false
        // manual override as changeStatus function would (and should) reject updates during initialization
        status = Self.status(for: locationManager.authorizationStatus, locationManager.accuracyAuthorization, and: mode)
        logger.info("Location service initialized with status \(self.status.debugDescription).")
        if status.isReceivingLocations {
            locationManager.startUpdatingLocation()
            logger.info("Location updates were requested after initialization.")
        }
    }
    
    func changeMode(to newMode: Mode) {
        guard self.mode != newMode else { return }
        logger.info("Changing mode to \(newMode.debugDescription).")
        mode = newMode
        locationManager.allowsBackgroundLocationUpdates = mode.allowsBackgroundLocationUpdates
        changeStatus(to: mode.correspondingStatus)
    }
    
    func requestAuthorization() throws(LocationServiceError) {
        switch status {
        case .deniedAuthorization: throw .authorizationDenied
        case .restrictedAuthorization: throw .authorizationRestricted
        default: break
        }
        locationManager.requestWhenInUseAuthorization()
        logger.info("Location authorization was requested.")
    }
    
    private func updateStatus(basedOn authStatus: CLAuthorizationStatus) {
        changeStatus(to: Self.status(for: authStatus, locationManager.accuracyAuthorization, and: mode))
    }
    
    private func changeStatus(to newStatus: Status) {
        guard status.canTransition, status != newStatus else { return }
        let oldStatus = status
        status = newStatus
        logger.info("Location service status changed to \(newStatus.debugDescription).")
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
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            self.location = location
        }
    }
        
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        switch (error as? CLError)?.code {
        case .locationUnknown, .network, .denied:
            logger.error("A temporary error was encountered: \(error.localizedDescription).")
        default:
            changeStatus(to: .failed(error))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        logger.info("Location authorization status updated to \(status.debugDescription)")
        updateStatus(basedOn: status)
    }
    
    // MARK: - Mode
    
    enum Mode: CustomDebugStringConvertible, Equatable {
        
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
        
        var debugDescription: String {
            switch self {
            case .idle: ".idle"
            case .recording: ".recording"
            }
        }
    }
    
    // MARK: - Status
    
    enum Status: CustomDebugStringConvertible, Equatable {
        
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
        var isReceivingLocations: Bool {
            switch self {
            case .idle, .recording: true
            default: false
            }
        }
        
        /// Indicates whether sufficient permission to record location data was granted by the user.
        var authorizationSufficient: Bool {
            switch self {
            case .missingAuthorization, .restrictedAuthorization, .deniedAuthorization: false
            default: true
            }
        }
        
        var debugDescription: String {
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
        
        static func == (lhs: Status, rhs: Status) -> Bool {
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
    
    enum LocationServiceError: LocalizedError, CustomDebugStringConvertible {
        
        case authorizationDenied
        case authorizationRestricted
        
        var debugDescription: String {
            switch self {
            case .authorizationDenied: "LocationServiceError.authorizationDenied"
            case .authorizationRestricted: "LocationServiceError.authorizationRestricted"
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .authorizationDenied: R.string.localizable.location_service_error_authorization_denied()
            case .authorizationRestricted: R.string.localizable.location_service_error_authorization_restricted()
            }
        }
    }
}
