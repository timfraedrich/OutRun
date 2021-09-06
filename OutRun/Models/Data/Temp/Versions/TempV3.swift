//
//  TempV3.swift
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

public enum TempV3 {
    
    public struct Workout: Codable, TempValueConvertible {
        
        public let uuid: UUID?
        public let workoutType: Int
        public let startDate: Date
        public let endDate: Date
        public let distance: Double
        public let steps: Int?
        public let isRace: Bool
        public let isUserModified: Bool
        public let comment: String?
        public let burnedEnergy: Double?
        public let healthKitUUID: UUID?
        public let workoutEvents: [TempV3.WorkoutEvent]
        public let locations: [TempV3.WorkoutRouteDataSample]
        public let heartRates: [TempV3.WorkoutHeartRateDataSample]
        
        public var asTemp: TempWorkout {
            
            let elevation = Computation.computeElevationData(
                from: locations.map { $0.altitude }
            )
            
            let pauseObjects = Computation.calculateAndValidatePauses(
                from: workoutEvents.map { (type: $0.eventType, date: $0.startDate) },
                workoutStart: startDate,
                workoutEnd: endDate
            ) ?? []
            
            let pauses = pauseObjects.map { (start, end, type) -> TempWorkoutPause in
                TempWorkoutPause(
                    uuid: nil,
                    startDate: start,
                    endDate: end,
                    pauseType: .init(rawValue: type)
                )
            }
            
            let durations = Computation.calculateDurationData(
                from: startDate,
                end: endDate,
                pauses: pauseObjects.map { (start: $0.start, end: $0.end) }
            )
            
            let events = workoutEvents.filter { $0.eventType > 3 }.map { $0.asTemp }
            
            return TempWorkout(
                uuid: uuid,
                workoutType: .init(rawValue: workoutType),
                distance: distance,
                steps: steps,
                startDate: startDate,
                endDate: endDate,
                burnedEnergy: burnedEnergy,
                isRace: isRace,
                comment: comment,
                isUserModified: isUserModified,
                healthKitUUID: healthKitUUID,
                finishedRecording: true,
                ascend: elevation.ascending,
                descend: elevation.descending,
                activeDuration: durations.activeDuration,
                pauseDuration: durations.pauseDuration,
                dayIdentifier: CustomDateFormatting.dayIdentifier(forDate: startDate),
                heartRates: heartRates.map { $0.asTemp },
                routeData: locations.map { $0.asTemp },
                pauses: pauses,
                workoutEvents: events
            )
        }
    }
    
    public struct WorkoutEvent: Codable, TempValueConvertible {
        
        public let uuid: UUID?
        public let eventType: Int
        public let startDate: Date
        public let endDate: Date
        
        public var asTemp: TempWorkoutEvent {
            
            if eventType > 3 {
                print("Conversion from TempV3.WorkoutEvent to TempWorkoutEvent invalid: eventType too high")
                fatalError()
            }
            
            return TempWorkoutEvent(
                uuid: uuid,
                eventType: .init(rawValue: eventType - 3),
                timestamp: startDate
            )
        }
    }
    
    public struct WorkoutRouteDataSample: Codable, TempValueConvertible {
        
        public let uuid: UUID?
        public let timestamp: Date
        public let latitude: Double
        public let longitude: Double
        public let altitude: Double
        public let horizontalAccuracy: Double
        public let verticalAccuracy: Double
        public let speed: Double
        public let direction: Double
        
        public var asTemp: TempWorkoutRouteDataSample {
            TempWorkoutRouteDataSample(
                uuid: self.uuid,
                timestamp: self.timestamp,
                latitude: self.latitude,
                longitude: self.longitude,
                altitude: self.altitude,
                horizontalAccuracy: self.horizontalAccuracy,
                verticalAccuracy: self.verticalAccuracy,
                speed: self.speed,
                direction: self.direction
            )
        }
    }
    
    public struct WorkoutHeartRateDataSample: Codable, TempValueConvertible {
        
        public let uuid: UUID?
        public let heartRate: Double
        public let timestamp: Date
        
        public var asTemp: TempWorkoutHeartRateDataSample {
            return TempWorkoutHeartRateDataSample(
                uuid: uuid,
                heartRate: Int(heartRate),
                timestamp: timestamp
            )
        }
    }
    
    public struct Event: Codable, TempValueConvertible {
        
        public let uuid: UUID?
        public let title: String
        public let comment: String?
        public let startDate: Date?
        public let endDate: Date?
        public let workouts: [UUID]
        
        public var asTemp: TempEvent {
            return TempEvent(
                uuid: uuid,
                title: title,
                comment: comment,
                startDate: startDate,
                endDate: endDate,
                workouts: workouts
            )
        }
    }
    
}
