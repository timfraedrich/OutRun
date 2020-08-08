//
//  WorkoutBuilderComponent.swift
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

protocol WorkoutBuilderComponent: AnyObject {
    
    /// the `WorkoutBuilder` currently holding this instance of `WorkoutBuilderComponent`
    var builder: WorkoutBuilder? { get set }
    
    /// a boolean indicating if the component is ready for a recording to be started
    var isReady: Bool { get set }
    
    /**
     Notifies the `WorkoutBuilderComponent` when the `WorkoutBuilder`s status changed
     - parameter oldStatus: the old status of the `WorkoutBuilder`
     - parameter newStatus: the new status of the `WorkoutBuilder`
     */
    func statusChanged(from oldStatus: WorkoutBuilder.Status, to newStatus: WorkoutBuilder.Status, timestamp: Date)
    
    /**
     Continues the recording process of a workout setting up the component like it was before finishing to record said workout
     */
    func continueWorkout(from snapshot: TempWorkout, timestamp: Date)
    
    /**
     Resets the `WorkoutBuilderComponent` making it ready for a new recording
     */
    func reset()
    
}

extension WorkoutBuilderComponent {
    
    func statusChanged(from oldStatus: WorkoutBuilder.Status, to newStatus: WorkoutBuilder.Status, timestamp: Date) {}
    
}
