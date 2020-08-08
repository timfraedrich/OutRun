//
//  CLLocation.swift
//
//  OutRun
//  Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import CoreLocation

extension CLLocation {
    
    func replacing(latitude: CLLocationDegrees? = nil, longitude: CLLocationDegrees? = nil, altitude: CLLocationDistance? = nil, horizontalAccuracy: CLLocationAccuracy? = nil, verticalAccuracy: CLLocationAccuracy? = nil, course: CLLocationDirection? = nil, speed: CLLocationSpeed? = nil, timeStamp: Date? = nil) -> CLLocation {
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude ?? self.coordinate.latitude, longitude: longitude ?? self.coordinate.longitude)
        
        return CLLocation(coordinate: coordinate, altitude: altitude ?? self.altitude, horizontalAccuracy: horizontalAccuracy ?? self.horizontalAccuracy, verticalAccuracy: verticalAccuracy ?? self.verticalAccuracy, course: course ?? self.course, speed: speed ?? self.speed, timestamp: timeStamp ?? self.timestamp)
    }
    
}
