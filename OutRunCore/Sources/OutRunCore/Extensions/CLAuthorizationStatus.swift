import CoreLocation

extension CLAuthorizationStatus {
    
    var isAuthorized: Bool {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse: true
        default: false
        }
    }
    
    var isDenied: Bool {
        switch self {
        case .denied, .restricted: true
        default: false
        }
    }
}

extension CLAuthorizationStatus: @retroactive CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .notDetermined: ".notDetermined"
        case .restricted: ".restricted"
        case .denied: ".denied"
        case .authorizedAlways: ".authorizedAlways"
        case .authorizedWhenInUse: ".authorizedWhenInUse"
        @unknown default: ".unknown"
        }
    }
}
