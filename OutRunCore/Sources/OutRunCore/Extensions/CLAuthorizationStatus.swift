//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
