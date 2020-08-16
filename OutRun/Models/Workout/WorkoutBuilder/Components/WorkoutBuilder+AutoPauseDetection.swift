//
//  WorkoutBuilder+AutoPauseDetection.swift
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

extension WorkoutBuilder {
    
    /// A `WorkoutBuilderComponent` for detecting automatic pauses during a workout
    class AutoPauseDetection: WorkoutBuilderComponent {
        
        // MARK: Public
        
        /**
         Updates the AutoPauseDetection instance with new values during a recording
         - parameter timestamp: the exact date when the data provided was received
         - parameter workoutType: the workout type of the current workout being recorded used for further analysis of the cenario and to discard auto pause detection when appropriate
         - parameter speed: the speed at the provided moment in meters per second
        */
        public func update(timestamp: Date, workoutType: Workout.WorkoutType, speed: Double) {
            
            guard !isManuallyPaused, speed >= 0, ![.walking, .hiking].contains(workoutType), let builder = self.builder, builder.status.isActiveStatus else {
                
                if self.currentPredictedStartDate?.distance(to: timestamp) ?? 0 > 10 {
                    
                    self.currentPredictedStartDate = nil
                    
                }
                
                return
            }
            
            // looking for end date
            if let predictedStartDate = self.currentPredictedStartDate {
                
                if speed >= 0.5 {
                    
                    if predictedStartDate.distance(to: timestamp) < 3 {
                        
                        self.currentPredictedStartDate = nil
                        
                    } else {
                        
                        if let autoPause = AutoPause(start: predictedStartDate, end: timestamp) {
                            detectedAutoPauses.append(autoPause)
                        }
                        self.currentPredictedStartDate = nil
                        
                    }
                }
                
            // looking for start date
            } else {
                
                if speed <= 0.25 {
                    if let lastPause = detectedAutoPauses.last {
                        
                        if lastPause.endDate.distance(to: timestamp) < 3 {
                            self.currentPredictedStartDate = lastPause.startDate
                            self.detectedAutoPauses.removeLast()
                            
                        } else {
                            
                            self.currentPredictedStartDate = timestamp
                            
                        }
                        
                    } else {
                        
                        self.currentPredictedStartDate = timestamp
                    }
                }
                
            }
            
            self.lastSpeed = speed
            
        }
        
        /**
         Stops the automatic pause detection and finishes the detection process
         - parameter timestamp: the exact date when the detection is supposed to have ended
         - returns: an array of the detected `AutoPause`s
        */
        public func finish(with timestamp: Date) -> [AutoPause] {
            
            let detectedAutoPauses = self.getAutoPauses(with: timestamp)
            
            self.reset()
            
            return detectedAutoPauses
        }
        
        /**
         Sets up the `AutoPauseDetection` with its old values after the `finished(with:)` method was run and the detection needs to be continued
         - parameter autoPauses: the array of formerly returned `AutoPause`s
         - parameter endDate: the date the workout was ended at; this is used to compare the last `AutoPause` end date and possibly continue an automatic pause
         - parameter timestamp: the date the workout was continued; there will be an automatic pause from stopping the workout until the continuation
        */
        public func setup(from autoPauses: [AutoPause], endDate: Date, timestamp: Date) {
            
            var autoPauses = autoPauses
            
            if autoPauses.last?.endDate == endDate {
                
                let lastPause = autoPauses.removeLast()
                if let newPause = AutoPause(start: lastPause.startDate, end: timestamp) {
                    autoPauses.append(newPause)
                }
                self.detectedAutoPauses = autoPauses
                
            } else {
                
                self.detectedAutoPauses = autoPauses
                
            }
            
        }
        
        /**
         Provides the current `AutoPause` objects without pausing the detection finishing an ongoing automatic pause when appropriate
         - parameter endDate: the date an ongoing automatic pause will end
         - returns: an array of recorded `AutoPause`s
         */
        public func getAutoPauses(with endDate: Date) -> [AutoPause] {
            
            var tempAutoPauses = self.detectedAutoPauses
            
            if let predictedStartDate = self.currentPredictedStartDate, predictedStartDate.distance(to: endDate) > 3 {
                
                if let autoPause = AutoPause(start: predictedStartDate, end: endDate) {
                    tempAutoPauses.append(autoPause)
                }
                
            }
            
            return tempAutoPauses
            
        }
        
        /**
         Provides the pause ranges which are needed to determine if something has happened during a pause or while the workout was actively being recorded
         - parameter date: the reference date for forming the intervals
         - returns: an array of `ClosedRange`s of type `Double` (`TimeInterval`) ranging from the start to the end interval of the `AutoPause`s in perspective to the provided date
         */
        public func getPauseRanges(with date: Date) -> [ClosedRange<Double>] {
            
            var ranges = self.detectedAutoPauses.map { (autoPause) -> ClosedRange<Double> in
                return autoPause.asRange(from: date)
            }
            
            if let predictedStartDate = self.currentPredictedStartDate {
                
                let startInterval = predictedStartDate.distance(to: date)
                let endInterval = date.distance(to: Date())
                let range = startInterval...endInterval
                
                ranges.append(range)
                
            }
            
            return ranges
            
        }
        
        // MARK: Protected
        
        /// boolean indicating if a manual pause was initiated
        private var isManuallyPaused: Bool = false
        /// detected `AutoPause` objects
        private var detectedAutoPauses: [AutoPause] = []
        /// the last know speed provided through the `update(timeStamp:workoutType:speed:)` method
        private var lastSpeed: Double? = nil
        /// current predicted start date for an automatic pause
        private var currentPredictedStartDate: Date? = nil {
            willSet {
                guard !isManuallyPaused, let builder = builder, builder.status.isActiveStatus else {
                    return
                }
                
                let newStatus: WorkoutBuilder.Status = newValue == nil ? .recording : .autoPaused
                
                builder.suggestNewStatus(newStatus) { isValid in
                    
                    if !isValid {
                        print("[WorkoutBuilder+AutoPauseDetection] Tried to make invalid status transition: (currentStatus: \(builder.status), suggestedStatus: \(newStatus)")
                    }
                    
                }
            }
        }
        
        // MARK: Initialisers
        
        /**
         Initialises the `AutoPauseDetection` object with a `WorkoutBuilder`
         - parameter builder: the workout builder currently holding this instance of `AutoPauseDetection`
         */
        convenience init(builder: WorkoutBuilder) {
            
            self.init()
            self.builder = builder
            
        }
        
        // MARK: WorkoutBuilderComponent - Protocol
        
        public weak var builder: WorkoutBuilder?
        
        public var isReady: Bool = true
        
        func statusChanged(from oldStatus: WorkoutBuilder.Status, to newStatus: WorkoutBuilder.Status, timestamp: Date) {
            
            if [.paused, .recording].contains(newStatus) {
                
                self.isManuallyPaused = newStatus == .paused
                
                if self.isManuallyPaused, let startDate = self.currentPredictedStartDate {
                    let endDate = timestamp.addingTimeInterval(-0.01)
                    if let autoPause = AutoPause(start: startDate, end: endDate) {
                        self.detectedAutoPauses.append(autoPause)
                    }
                    self.currentPredictedStartDate = nil
                }
                
            }
            
        }
        
        func continueWorkout(from snapshot: TempWorkout, timestamp: Date) {
            
            // the old auto pauses are already integrated into the workout data, so no need to readd them here
            self.reset()
            
        }
        
        func reset() {
            
            self.detectedAutoPauses = []
            self.lastSpeed = nil
            self.currentPredictedStartDate = nil
            self.isManuallyPaused = false
            
        }
        
    }
    
}
