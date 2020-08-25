//
//  DataModelValueGetters.swift
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
import CoreStore

enum DataModelValueGetters {
    
    static func activeDuration(_ partialObject: PartialObject<Workout>) -> Double {
        let start = partialObject.value(for: { $0.startDate })
        let end = partialObject.value(for: { $0.endDate })
        let pauseDuration = partialObject.value(for: { $0.pauseDuration })
        return end.distance(to: start) - pauseDuration
    }
    static func pauseDuration(_ partialObject: PartialObject<Workout>) -> Double {
        var duration: Double = 0.0
        var pauseDate: Date?
        let events = partialObject.completeObject().workoutEvents.value
        events.enumerated().forEach { (index, event) in
            if (event.type == .pause || event.type == .autoPause), pauseDate == nil {
                pauseDate = event.startDate.value
                
            } else if (event.type == .resume || event.type == .autoResume), let pause = pauseDate {
                duration += event.startDate.value.distance(to: pause)
                pauseDate = nil
            }
            
            if (index + 1) == events.count, let pause = pauseDate, let end = partialObject.value(for: { $0.endDate }) as Optional, end >= pause {
                duration += end.distance(to: pause)
            }
        }
        return duration
    }
    static func dayIdentifier(_ partialObject: PartialObject<Workout>) -> String {
        return CustomTimeFormatting.dayIdentifier(forDate: partialObject.value(for: { $0.startDate }))
    }
    static func dimensionalAltitudes(_ partialObject: PartialObject<Workout>) -> (Double, Double) {
        let altitudes = partialObject.completeObject().routeData.map { (sample) -> Double in return sample.altitude.value }
        var tempAscending: Double = 0
        var tempDescending: Double = 0
        var lastRoundedAltitude: Double?
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
            guard let lastRounded = lastRoundedAltitude else {
                lastRoundedAltitude = rounded
                continue
            }
            let difference = rounded - lastRounded
            if difference > 0 {
                tempAscending += difference
            } else if difference < 0 {
                tempDescending += abs(difference)
            }
            lastRoundedAltitude = rounded
        }
        tempAscending.round()
        tempDescending.round()
        return (tempAscending, tempDescending)
    }
    static func ascendingAltitude(_ partialObject: PartialObject<Workout>) -> Double {
        return dimensionalAltitudes(partialObject).0
    }
    static func descendingAltitude(_ partialObject: PartialObject<Workout>) -> Double {
        return dimensionalAltitudes(partialObject).1
    }
    
    static func duration(_ partialObject: PartialObject<WorkoutEvent>) -> Double {
        let start = partialObject.value(for: { $0.startDate })
        let end = partialObject.value(for: { $0.endDate })
        return end.distance(to: start)
    }
    
    static func startDate(_ partialObject: PartialObject<Event>) -> Date? {
        return partialObject.completeObject().workouts.min { (workout1, workout2) -> Bool in
                return workout1.startDate.value > workout2.startDate.value
            }?.startDate.value
    }
    static func endDate(_ partialObject: PartialObject<Event>) -> Date? {
        return partialObject.completeObject().workouts.max { (workout1, workout2) -> Bool in
                return workout1.endDate.value > workout2.endDate.value
            }?.endDate.value
    }
    
}
