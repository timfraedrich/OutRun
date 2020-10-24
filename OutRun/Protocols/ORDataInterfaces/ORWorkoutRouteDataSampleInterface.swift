//
//  ORWorkoutRouteDataSampleInterface.swift
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

/// A protocol to unify the saving and processing of route data samples connected to a workout.
protocol ORWorkoutRouteDataSampleInterface: AnyObject {
    
    /// The universally unique identifier used to identify a `WorkoutRouteDataSample` in the data base. If `nil` the route data sample might not be saved yet, a UUID will be asigned once saved.
    var uuid: UUID? { get }
    /// The `Date` the route data sample was recorded at.
    var timestamp: Date { get }
    /// The latitude of the location the route data sample was recorded at.
    var latitude: Double { get }
    /// The longitude of the location the route data sample was recorded at.
    var longitude: Double { get }
    /// The altitude of the location the route data sample was recorded at.
    var altitude: Double { get }
    /// The estimated accuracy of the `latitude` and `longitude` values.
    var horizontalAccuracy: Double { get }
    /// The estimated accuracy of the `altitude` in meters.
    var verticalAccuracy: Double { get }
    /// The current speed at the time in meters per second.
    var speed: Double { get }
    /// The direction the device was moving in at the time.
    var direction: Double { get }
    /// A reference to the `Workout` this route data sample is associated with.
    var workout: ORWorkoutInterface? { get }
    
}
