//
//  WorkoutBuilder+StepCounter.swift
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
import CoreMotion

extension WorkoutBuilder {
    
    /// A `WorkoutBuilderComponent` for counting the steps taken during a workout
    class StepCounter: WorkoutBuilderComponent {
        
        // MARK: Public
        
        /// the amount of counted steps; if `nil` step counting is not available
        public private(set) var steps: Int? = nil
        
        /// If `true` the `StepCounter` will be able to collect data
        public var isDataAvailable: Bool {
            return CMPedometer.isStepCountingAvailable()
        }
        
        // MARK: Protected
        
        /// the amount of steps before the last pause
        private var stepsBeforeLastPause: Int? = nil
        /// a boolean indicating whether steps should be recorded
        private var shouldRecord: Bool = false
        /// the pedometer instance used to count the steps
        private let pedometer: CMPedometer = CMPedometer()
        
        /**
         Starts updating the steps from the provided date until it stops itself
         - parameter date: the date from which on steps will be recognised
         */
        private func startUpdating(from date: Date) {
            
            if CMPedometer.isStepCountingAvailable() {
                
                self.pedometer.startUpdates(from: date) { (data, error) in
                    
                    guard self.shouldRecord else {
                        
                        self.stepsBeforeLastPause = self.steps
                        self.pedometer.stopUpdates()
                        return
                        
                    }
                    
                    if let steps = data?.numberOfSteps {
                        
                        if let oldSteps = self.stepsBeforeLastPause {
                            
                            self.steps = Int(truncating: steps) + oldSteps
                            
                        } else {
                            
                            self.steps = Int(truncating: steps)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
        // MARK: Initialisers
        
        /**
         Initialises the `StepCounter` object with a `WorkoutBuilder`
         - parameter builder: the workout builder currently holding this instance of `StepCounter`
         */
        convenience init(builder: WorkoutBuilder) {
            
            self.init()
            self.builder = builder
            
        }
        
        // MARK: WorkoutBuilderComponent - Protocol
        
        public weak var builder: WorkoutBuilder?
        
        public var isReady: Bool = true
        
        func statusChanged(from oldStatus: WorkoutBuilder.Status, to newStatus: WorkoutBuilder.Status, timestamp: Date) {
            
            if newStatus == .recording {
                
                self.shouldRecord = true
                self.startUpdating(from: timestamp)
                
            } else {
                
                self.shouldRecord = false
                
            }
            
        }
        
        func continueWorkout(from snapshot: TempWorkout, timestamp: Date) {
            
            self.steps = snapshot.steps
            self.stepsBeforeLastPause = snapshot.steps
            
            self.shouldRecord = true
            self.startUpdating(from: timestamp)
            
        }
        
        func reset() {
            
            self.pedometer.stopUpdates()
            
            self.steps = nil
            self.stepsBeforeLastPause = nil
            self.shouldRecord = false
            
        }
        
    }
    
}
