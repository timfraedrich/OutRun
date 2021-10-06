//
//  ORWorkoutPauseInterface.swift
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

/// A protocol to unify the saving and processing of pause objects connected to a workout.
public protocol ORWorkoutPauseInterface: ORDataInterface {
    
    /// The universally unique identifier used to identify a `WorkoutPause` in the data base. If `nil` the pause might not be saved yet, a UUID will be asigned once saved.
    var uuid: UUID? { get }
    /// The `Date` the pause started at.
    var startDate: Date { get }
    /// The `Date` the pause ended at.
    var endDate: Date { get }
    /// The type of the pause. For more see `WorkoutPause.WorkoutPauseType`.
    var pauseType: WorkoutPause.WorkoutPauseType { get }
    /// A reference to the `Workout` this pause is associated with.
    var workout: ORWorkoutInterface? { get }
    
}

public extension ORWorkoutPauseInterface {
    
    var uuid: UUID? { throwOnAccess() }
    var startDate: Date { throwOnAccess() }
    var endDate: Date { throwOnAccess() }
    var pauseType: WorkoutPause.WorkoutPauseType { throwOnAccess() }
    var workout: ORWorkoutInterface? { throwOnAccess() }
    
    /// The duration of a pause, meaning the distance between the start and end date.
    var duration: TimeInterval {
        return startDate.distance(to: endDate)
    }
    
    /**
     Conversion of the TempWorkoutPause object into a Range.
     - parameter date: the reference date for forming the intervals
     - returns: a `ClosedRange` of type Double ranging from the start to the end interval of the `TempWorkoutPause` in perspective to the provided date
    */
    func asRange(from date: Date) -> ClosedRange<Double> {
        
        let startInterval = self.startDate.distance(to: date)
        let endInterval = self.endDate.distance(to: date)
        
        return startInterval...endInterval
        
    }
    
    /**
     Checks if a date is contained in the date range of a pause object.
     - parameter date: the date that is supposed to be checked
     - returns: a boolean indicating whether the date is contained within the pause data range
     */
    func contains(_ date: Date) -> Bool {
        return (startDate...endDate).contains(date)
    }
    
}
