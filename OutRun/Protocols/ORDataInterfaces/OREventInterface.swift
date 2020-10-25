//
//  OREventInterface.swift
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

/// A protocol to unify the saving and processing events.
protocol OREventInterface: AnyObject {
    
    /// The universally unique identifier used to identify a `Event` in the data base. If `nil` the event might not be saved yet, a UUID will be asigned once saved.
    var uuid: UUID? { get }
    /// The title of the event, describing it as short as possible.
    var title: String { get }
    /// A `String` providing additional information on an event. If `nil` none has been set.
    var comment: String? { get }
    /// The first `startDate` of the `Workout`s associated with this event.
    var startDate: Date? { get }
    /// The last `endDate` of the `Workout`s associated with this event.
    var endDate: Date? { get }
    /// A reference to the `Workout`s associated with this event.
    var workouts: [ORWorkoutInterface] { get }
    
}
