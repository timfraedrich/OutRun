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
import RxSwift

public protocol WorkoutBuilderComponent: AnyObject {
    
    /**
     Initiates the `WorkoutBuilderComponent` from a `WorkoutBuilder`.
     - parameter builder: the workout builder the component is supposed to be bound to
     */
    init(builder: WorkoutBuilder)
    
    /**
     Binds this component to the provided `WorkoutBuilder`.
     - parameter builder: the workout builder the component is supposed to be bound to
     */
    func bind(builder: WorkoutBuilder)
    
    /**
     Continues the recording process of a workout setting up the component like it was before finishing to record said workout.
     - parameter snapshot: the state of the recorded workout supposed to be restored
     - parameter timestamp: the exact date when the restoration action was scheduled
     */
    func continueWorkout(from snapshot: ORWorkoutInterface, at timestamp: Date)
    
    /**
     Resets the `WorkoutBuilderComponent` making it ready for a new recording.
     */
    func reset()
    
}
