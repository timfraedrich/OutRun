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

enum TempV3 {
    
    struct Workout: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let workoutType: Int
        let startDate: Date
        let endDate: Date
        let distance: Double
        let steps: Int?
        let isRace: Bool
        let isUserModified: Bool
        let comment: String?
        let burnedEnergy: Double?
        let healthKitUUID: UUID?
        let workoutEvents: [TempV3.WorkoutEvent]
        let locations: [TempV3.WorkoutRouteDataSample]
        let heartRates: [TempV3.WorkoutHeartRateDataSample]
        
        var asTemp: TempWorkout {
            
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
    
    struct WorkoutEvent: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let eventType: Int
        let startDate: Date
        let endDate: Date
        
        var asTemp: TempWorkoutEvent {
            
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
    
    struct WorkoutRouteDataSample: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let horizontalAccuracy: Double
        let verticalAccuracy: Double
        let speed: Double
        let direction: Double
        
        var asTemp: TempWorkoutRouteDataSample {
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
    
    struct WorkoutHeartRateDataSample: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let heartRate: Double
        let timestamp: Date
        
        var asTemp: TempWorkoutHeartRateDataSample {
            return TempWorkoutHeartRateDataSample(
                uuid: uuid,
                heartRate: Int(heartRate),
                timestamp: timestamp
            )
        }
    }
    
    struct Event: Codable, TempValueConvertible {
        
        let uuid: UUID?
        let title: String
        let comment: String?
        let startDate: Date?
        let endDate: Date?
        let workouts: [UUID]
        
        var asTemp: TempEvent {
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
