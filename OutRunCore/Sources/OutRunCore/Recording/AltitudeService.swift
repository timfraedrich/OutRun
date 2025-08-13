import Combine
import CoreMotion
import Foundation
import OSLog

/// A class gathering of altitude updates.
/// - note: While an approximate altitude is received with the users location, this class allows for refinement of location samples.
class AltitudeService: ObservableObject {
    
    private let logger = Logger(category: "AltitudeService")
    private let operationQueue = OperationQueue()
    private let altimeter = CMAltimeter()
    @Published private(set) var status: Status
    @Published private(set) var mode: Mode
    @Published private(set) var lastAltitude: AltitudeSample?
    
    init() {
        status = .idle
        mode = if CMAltimeter.isAbsoluteAltitudeAvailable() {
            .absoluteAltitudeAvailable
        } else if CMAltimeter.isRelativeAltitudeAvailable() {
            .relativeAltitudeAvailable
        } else {
            .noAlitudeAvailable
        }
        logger.info("Initialized with mode: \(self.mode.debugDescription)")
    }
    
    /// Starts altitude updates.
    /// - warning: Calling this method while altitude data is being collected will perform a restart of the data collection and update the
    /// ``status`` accordingly.
    func start() {
        switch status {
        case .failed:
            logger.error("Tried to start altitude updates in failed state.")
            return
        case .updatingSince:
            logger.fault("Started altitude updates while already updating, triggering a reset.")
            reset()
        default: break
        }
        status = .updatingSince(.now)
        switch mode {
        case .absoluteAltitudeAvailable:
            altimeter.startAbsoluteAltitudeUpdates(to: operationQueue) { [weak self] altitudeData, error in
                guard let self else { return }
                if let altitudeData {
                    lastAltitude = .init(isAbsolute: true, timestamp: .now, altitude: Float(altitudeData.altitude))
                } else if let error {
                    reset()
                    status = .failed(error)
                }
            }
            logger.info("Started absolute altitude updates.")
        case .relativeAltitudeAvailable:
            altimeter.startRelativeAltitudeUpdates(to: operationQueue) { [weak self] altitudeData, error in
                guard let self else { return }
                if let altitudeData {
                    lastAltitude = .init(isAbsolute: false, timestamp: .now, altitude: Float(truncating: altitudeData.relativeAltitude))
                } else if let error {
                    reset()
                    status = .failed(error)
                }
            }
            logger.info("Started relative altitude updates.")
        case .noAlitudeAvailable:
            logger.info("Altitude updates are not supported on this device.")
        }
    }
    
    /// Stops altitude updates and resets this class.
    func reset() {
        switch mode {
        case .absoluteAltitudeAvailable: altimeter.stopAbsoluteAltitudeUpdates()
        case .relativeAltitudeAvailable: altimeter.stopRelativeAltitudeUpdates()
        case .noAlitudeAvailable: break
        }
        lastAltitude = nil
        status = .idle
        logger.info("Reset altitude service and stopped altitude updates.")
    }
    
    // MARK: - AltitudeSample
    
    struct AltitudeSample {
        
        /// Indicates whether the ``altitude`` variable describes an absolute value or relative change to the start date.
        let isAbsolute: Bool
        /// The timestamp at which the altitude was recorded.
        let timestamp: Date
        /// The relative value of the altitude.
        let altitude: Float
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
        
        /// Waiting to collect altitude updates. Call ``AltitudeService/start()`` to start.
        case idle
        /// Currently receiving altitude updates. Refer to the mode to determine which kind.
        case updatingSince(Date)
        /// Failed with the specified error.
        case failed(Error)
        
        var debugDescription: String {
            switch self {
            case .idle: ".idle"
            case .updatingSince(let date): ".updatingSince(\(date.formatted(.iso8601)))"
            case .failed(let error): ".failed(\((error as NSError).debugDescription)"
            }
        }
        
        static func == (lhs: Status, rhs: Status) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.failed, .failed): true
            case (.updatingSince(let lhsDate), .updatingSince(let rhsDate)): lhsDate == rhsDate
            default: false
            }
        }
    }
}
