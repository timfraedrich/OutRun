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

/// A protocol to unify the saving and processing of objects holding workout data.
protocol ORWorkoutInterface: AnyObject {
    
    /// The universally unique identifier used to identify a `Workout` in the data base and when transferring it from somewhere else. If `nil` the workout might not be saved inside the database yet, a UUID will be asigned once saved.
    var uuid: UUID? { get }
    /// The type of the underlying workout. For more see `Workout.WorkoutType`.
    var workoutType: Workout.WorkoutType { get }
    /// The distance travelled during the workout in meters.
    var distance: Double { get }
    /// The steps taken during the workout. If `nil`, no steps were recorded or it does not make sense to assign a step value to the workout because of its type.
    var steps: Int? { get }
    /// The `Date` the workout was started at.
    var startDate: Date { get }
    /// The `Date` the workout was ended at.
    var endDate: Date { get }
    /// An estimate of energy burned during the workout in kilocalories. If `nil` no estimate could be made or the workout was imported without data being attached.
    var burnedEnergy: Double? { get }
    /// A boolean indicating whether the recorded workout was a competition.
    var isRace: Bool { get }
    /// A `String` providing additional information on a workout. If `nil` none has been set.
    var comment: String? { get }
    /// A boolean indicating whether the workout was modified be the user.
    var isUserModified: Bool { get }
    /// The universally unique identifier provided by Apple Health and attached to the workout if it was imported from or saved to the HealthStore. If `nil` there is no known reference to the workout in Apple Health.
    var healthKitUUID: UUID? { get }
    /// The height gained during the workout in meters.
    var ascend: Double { get }
    /// The height lossed during the workout in meters.
    var descend: Double { get }
    /// The duration the user was actively working out, meaning the workout was neither automatically nor manually paused.
    var activeDuration: Double { get }
    /// The duration the workout was paused.
    var pauseDuration: Double { get }
    /// A String to identify the specific day a workout was recorded on taken from the `startDate` property. The format of the date is `yyyyMMdd`.
    var dayIdentifier: String { get }
    /// A reference to `WorkoutHeartRateSamples` associated with this workout.
    var heartRates: [ORWorkoutHeartRateDataSampleInterface] { get }
    /// A reference to `WorkoutRouteDataSamples` associated with this workout.
    var routeData: [ORWorkoutRouteDataSampleInterface] { get }
    /// A reference to `WorkoutPause`s associated with this workout.
    var pauses: [ORWorkoutPauseInterface] { get }
    /// A reference to `WorkoutEvent`s associated with this workout.
    var workoutEvents: [ORWorkoutEventInterface] { get }
    /// A reference to `Event`s associated with this workout.
    var events: [OREventInterface] { get }
    
}
