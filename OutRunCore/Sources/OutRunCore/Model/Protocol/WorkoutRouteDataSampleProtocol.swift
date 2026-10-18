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
import Foundation

public protocol WorkoutRouteDataSampleProtocol: Equatable {
    var timestamp: Date { get }
    var latitude: Double { get }
    var longitude: Double { get }
    var altitude: Float { get }
    /// - note: This value is only valid if it is greater than zero.
    var horizontalAccuracy: Float { get }
    /// - note: This value is only valid if it is greater than zero.
    var verticalAccuracy: Float { get }
    /// - note: This value is only valid if it is greater or equal to zero.
    var speed: Float { get }
}

public extension WorkoutRouteDataSampleProtocol {
    
    static var invalidSpeed: Float { -1 }
    static var invalidHorizontalAccuracy: Float { 0 }
    static var invalidVerticalAccuracy: Float { 0 }
    
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var validatedSpeed: Float? { speed >= 0 ? speed : nil }
    var validatedAltitude: Float? { verticalAccuracy > 0 ? altitude : nil }
}
