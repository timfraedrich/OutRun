//
//  WorkoutBuilder+AutoPause.swift
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
    
    struct AutoPause {
        
        /// the date the AutoPause start was detected
        let startDate: Date
        /// the date the AutoPause end was detected
        let endDate: Date
        
        /**
         Combining two instances of the AutoPause object into one
         - parameter with: the `AutoPause` object to merge
         - returns: one `AutoPause` instance with the earliest start date and the latest end date of the provided and `self`; if the initialisation with the new dates fails `self` will be returned
        */
        func merge(with anotherPause: AutoPause) -> AutoPause {
            
            let commonStart = startDate < anotherPause.startDate ? startDate : anotherPause.startDate
            let commonEnd = endDate > anotherPause.endDate ? endDate : anotherPause.endDate
            
            return AutoPause(start: commonStart, end: commonEnd) ?? self
            
        }
        
        /**
         Conversion of the AutoPause object into TempWorkoutEvents
         - returns: an array of an autoPause and an autoResume TempWorkoutEvent
         */
        func asWorkoutEvents() -> [TempWorkoutEvent] {
            let startEvent = TempWorkoutEvent(type: .autoPause, date: startDate)
            let endEvent = TempWorkoutEvent(type: .autoResume, date: endDate)
            return [startEvent, endEvent]
        }
        
        /**
         Conversion of the AutoPause object into a Range
         - parameter date: the reference date for forming the intervals
         - returns: a `ClosedRange` of type Double ranging from the start to the end interval of the `AutoPause` in perspective to the provided date
        */
        func asRange(from date: Date) -> ClosedRange<Double> {
            
            let startInterval = self.startDate.distance(to: date)
            let endInterval = self.endDate.distance(to: date)
            
            return startInterval...endInterval
            
        }
        
        /**
         Initialises an `AutoPause` object with the provided datesif the start is earlier than the end
         - parameter start: the start date of the automatic pause
         - parameter end: the end date of the automatic pause
         */
        init?(start: Date, end: Date) {
            
            guard start < end else {
                return nil
            }
            
            self.startDate = start
            self.endDate = end
            
        }
        
        /**
         Conversion of an array of `AutoPause`s to an array of `TempWorkoutEvent`s
         - parameter array: the provided array of `AutoPause`s
         - returns: an array of `TempWorkoutEvent`s
         */
        static func convertToEvents(with array: [AutoPause]) -> [TempWorkoutEvent] {
            
            var events = [TempWorkoutEvent]()
            
            for pause in array {
                
                events.append(contentsOf: pause.asWorkoutEvents())
                
            }
            
            return events.sorted { (event1, event2) -> Bool in
                event1.startDate < event2.startDate
            }
            
        }
        
        
    }
    
}
