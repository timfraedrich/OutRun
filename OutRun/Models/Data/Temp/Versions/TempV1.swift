//
//  TempV1.swift
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

public enum TempV1 {
    
    public struct Workout: Codable, TempValueConvertible {
        
        public let uuid: UUID?
        public let workoutType: Int
        public let startDate: Date
        public let endDate: Date
        public let distance: Double
        public let burnedEnergy: Double
        public let healthKitUUID: UUID?
        public let locations: [TempV1.RouteDataSample]
        
        public var asTemp: TempWorkout {
            
            let elevation = Computation.computeElevationData(
                from: locations.map { $0.altitude }
            )
            
            let durations = Computation.calculateDurationData(
                from: startDate,
                end: endDate
            )
            
            return TempWorkout(
                uuid: uuid,
                workoutType: .init(rawValue: workoutType),
                distance: distance,
                steps: nil,
                startDate: startDate,
                endDate: endDate,
                burnedEnergy: burnedEnergy,
                isRace: false,
                comment: nil,
                isUserModified: false,
                healthKitUUID: healthKitUUID,
                finishedRecording: true,
                ascend: elevation.ascending,
                descend: elevation.descending,
                activeDuration: durations.activeDuration,
                pauseDuration: 0,
                dayIdentifier: CustomDateFormatting.dayIdentifier(forDate: self.startDate),
                heartRates: [],
                routeData: locations.map { $0.asTemp },
                pauses: [],
                workoutEvents: []
            )
        }
        
    }
    
    public struct RouteDataSample: Codable, TempValueConvertible {
        
        public let uuid: UUID?
        public let timestamp: Date
        public let latitude: Double
        public let longitude: Double
        public let altitude: Double
        public let speed: Double
        public let direction: Double
        
        public var asTemp: TempWorkoutRouteDataSample {
            TempWorkoutRouteDataSample(
                uuid: self.uuid,
                timestamp: self.timestamp,
                latitude: self.latitude,
                longitude: self.longitude,
                altitude: self.altitude,
                horizontalAccuracy: 0,
                verticalAccuracy: 0,
                speed: self.speed,
                direction: self.direction
            )
        }
    }
    
}
