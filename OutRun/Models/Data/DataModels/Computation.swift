//
//  [FILENAME]
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

/// A static class to standardise the computation of data properties across the app
class Computation {
    
    typealias DurationTouple = (activeDuration: TimeInterval, pauseDuration: TimeInterval)
    typealias ElevationTouple = (ascending: Double, descending: Double)
    typealias EventTouple = (type: Int, date: Date)
    typealias PauseTouple = (start: Date, end: Date, type: Int)
    typealias RawPauseTouple = (start: Date, end: Date)
    
    /**
     Computes the elevation changes (ascending and descending) from altitudes of a workouts route
     - parameter altitudes: the provided elevations from the route data samples
     - returns: the calculated ascending and descending altitude in a touple of two values
     */
    static func computeElevationData(from altitudes: [Double]) -> ElevationTouple {
        
        var tempAscending: Double = 0
        var tempDescending: Double = 0
        
        let threshold = 1.5
        
        var lastConsideredRoundedAltitude: Double?
        
        for (index, value) in altitudes.enumerated() {
            
            var tempSum = value
            var tempCount: Double = 1
            
            for i in (index - 5)...(index + 5) where altitudes.indices.contains(i) {
                if let altitude = altitudes.safeValue(for: i) {
                    tempSum += altitude
                    tempCount += 1
                }
            }
            let rounded = (tempSum / tempCount)
            
            guard let lastRounded = lastConsideredRoundedAltitude else {
                lastConsideredRoundedAltitude = rounded
                continue
            }
            
            let difference = rounded - lastRounded
            
            if abs(difference) >= threshold {
                if difference > 0 {
                    tempAscending += difference
                } else if difference < 0 {
                    tempDescending += abs(difference)
                }
                lastConsideredRoundedAltitude = rounded
            }
        }
        
        return (tempAscending, tempDescending)
        
    }
    
    /**
     Computes the duration data (active and pause duration) from the according dates of the workout and pause objects.
     - parameter start: the start date of the workout
     - parameter end: the end date of the workout
     - parameter pauses: an array of tuples representing the start and end dates of pause objects
     - returns: the calculated active and pause duration in a tuple of two values
     */
    static func calculateDurationData(from start: Date, end: Date, pauses: [RawPauseTouple] = []) -> DurationTouple {
        
        let totalDuration = start.distance(to: end)
        var pauseDuration: TimeInterval = 0
        
        for pause in pauses {
            let duration = pause.start.distance(to: pause.end)
            pauseDuration += duration
        }
        
        return (totalDuration - pauseDuration, pauseDuration)
        
    }
    
    /**
     Computes and validates pauses from workout event data.
     - parameter events: the events from which the pauses are supposed to be calculated
     - parameter workoutStart: the start date of the workout to which the pauses are linked
     - parameter workoutEnd: the start date of the workout to which the pauses are linked
     - returns: the calculated pause objects; if `nil` the validation failed
     */
    static func calculateAndValidatePauses(from events: [EventTouple], workoutStart: Date, workoutEnd: Date) -> [PauseTouple]? {
        
        // validation -> pauses are not taken to next version if this fails
        
        // date range
        if events.contains(where: { (event) -> Bool in
            event.date < workoutStart || event.date > workoutEnd
        }) {
           return nil
        }
        
        // starts with pause (manual pause == 0; automatic pause == 1)
        if ![nil, 0, 1].contains(events.first?.type) {
            return nil
        }
        
        // shouldnt contain more resume than pause objects
        let pauseCount = events.filter { (event) -> Bool in [0, 1].contains(event.type)}.count
        let resumeCount = events.filter { (event) -> Bool in [2, 3].contains(event.type)}.count
        if pauseCount < resumeCount {
            return nil
        }
        
        // pause objects can be build from the data
        var pauseData: [(start: Date, end: Date, type: Int)] = []
        for (index, pauseEvent) in events.enumerated() where [0, 1].contains(pauseEvent.type) {
            
            let pauseType = pauseEvent.type
            
            if let resumeEvent = events.safeValue(for: index + 1), resumeEvent.type == pauseEvent.type + 2 {
                pauseData.append((start: pauseEvent.date, end: resumeEvent.date, type: pauseType))
                
            } else if index == events.count - 1 {
                pauseData.append((start: pauseEvent.date, end: workoutEnd, type: pauseType))
                
            } else {
                return nil
            }
            
            // check for overlaps
            let dataPoint = pauseData.last!
            let range = dataPoint.start...dataPoint.end
            
            for otherDataPoint in pauseData.dropLast() {
                
                // check for duplicate
                if dataPoint == otherDataPoint {
                    return nil
                }
                
                // check for overlap
                let otherRange = otherDataPoint.start...otherDataPoint.end
                if range.overlaps(otherRange) {
                    return nil
                }
                
            }
        }
        
        return pauseData
        
    }
    
}
