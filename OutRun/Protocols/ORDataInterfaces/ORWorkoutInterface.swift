//
//  ORWorkoutInterface.swift
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

protocol ORWorkoutInterface: AnyObject {
    
    var uuid: UUID? { get }
    var workoutType: Workout.WorkoutType { get }
    var distance: Double { get }
    var steps: Int? { get }
    var startDate: Date { get }
    var endDate: Date { get }
    var burnedEnergy: Double? { get }
    var isRace: Bool { get }
    var comment: String? { get }
    var isUserModified: Bool { get }
    var healthKitUUID: UUID? { get }
    var ascend: Double { get }
    var descend: Double { get }
    var activeDuration: Double { get }
    var pauseDuration: Double { get }
    var dayIdentifier: String { get }
    var heartRates: [ORWorkoutHeartRateDataSampleInterface] { get }
    var routeData: [ORWorkoutRouteDataSampleInterface] { get }
    var pauses: [ORWorkoutPauseInterface] { get }
    var workoutEvents: [ORWorkoutEventInterface] { get }
    var events: [OREventInterface] { get }
    
}
