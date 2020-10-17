//
//  WorkoutCompletionActionHandler.swift
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
import UIKit

class WorkoutCompletionActionHandler {
    
    /// A `TempWorkout` object to be saved, discarded or handed back to a `WorkoutBuilder` by this class
    private var snapshot: TempWorkout
    
    /// A weak reference to a `WorkoutBuilder` to continue the workout
    private weak var builder: WorkoutBuilder?
    
    /// If `true` the `WorkoutCompletionActionHandler` did already perform an action, so no additional action should be taken
    private var didPerformAction: Bool = false
    
    /**
     Initialises the `WorkoutCompletionActionHandler` with the needed snapshot of an `TempWorkout`
     - parameter snapshot: a `TempWorkout` object to be saved, discarded or continued
     */
    public init(snapshot: TempWorkout, builder: WorkoutBuilder) {
        
        self.snapshot = snapshot
        self.builder = builder
        
    }
    
    /**
     Displays a dismissable view over the current `UIWindow` that gives the user options on what to do with the just recorded workout, saving it automatically after a certain time
     */
    public func display() {
        
        let banner = WorkoutCompletionBanner(handler: self)
        
        banner.show(queuePosition: .front)
        
    }
    
    /**
     Saves the workout if no other action was already performed
     */
    public func saveWorkout() {
        
        guard !self.didPerformAction else {
            return
        }
        
        self.didPerformAction = true
        
        DataManager.saveWorkout(tempWorkout: self.snapshot) { (success, error, workout) in
            
            let banner = TextBanner(text: LS["NewWorkoutCompletion.Save." + (success ? "Success" : "Error")])
            banner.duration = 5
            banner.show()
            
        }
        
    }
    
    /**
     Continues the workout if no other action was already performed and the builder is still active
     */
    public func continueWorkout() {
        
        guard !self.didPerformAction else {
            return
        }
        
        self.didPerformAction = true
        
        var messageKey = ""
        
        if let builder = self.builder {
            
            builder.continueWorkout(from: self.snapshot)
            
            messageKey = "NewWorkoutCompletion.Continue.Success"
            
        } else {
            
            messageKey = "NewWorkoutCompletion.Continue.Error"
            
        }
        
        let banner = TextBanner(text: LS[messageKey])
        banner.duration = 5
        banner.show()
        
        print("Imagine the workout would continue")
        
    }
    
    /**
     Discards the workout if no other action was already performed
     */
    public func discardWorkout() {
        
        guard !self.didPerformAction else {
            return
        }
        
        self.didPerformAction = true
        
    }
    
}
