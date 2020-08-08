//
//  RouteDataSample.swift
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

import Foundation
import CoreLocation

typealias WorkoutRouteDataSample = OutRunV3.WorkoutRouteDataSample

extension WorkoutRouteDataSample: CustomStringConvertible, WorkoutSeriesDataSampleType {
    
    var description: String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: timestamp.value as Date)
        
        return "RouteDataSample(latitude: \(latitude), longitude: \(longitude), altitude: \(altitude), direction: \(direction), speed: \(speed), timeStamp: \(dateString))"
    }
    
    var clLocation: CLLocation? {
        
        let coordinate = CLLocationCoordinate2D(latitude: self.latitude.value, longitude: self.longitude.value)
        let location = CLLocation(coordinate: coordinate, altitude: self.altitude.value, horizontalAccuracy: 0, verticalAccuracy: 0, course: self.direction.value, speed: self.speed.value, timestamp: timestamp.value)
        
        return location
    }
    
}
