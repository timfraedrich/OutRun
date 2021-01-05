//
//  Workout.swift
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
import CoreLocation
import HealthKit

typealias Workout = OutRunV3.Workout

extension Workout: CustomStringConvertible {
    
    var type: WorkoutType {
        get {
            return WorkoutType(rawValue: self.workoutType.value)
        }
    }
    
    private var tmpAddress: String {
        get {
            return String(format: "%p", unsafeBitCast(self, to: Int.self))
        }
    }
    private static var _stats = [String:WorkoutStats]()
    var cachedStats: WorkoutStats? {
        get {
            return Workout._stats[tmpAddress] ?? nil
        } set(newValue) {
            Workout._stats[tmpAddress] = newValue
        }
    }
    
    var hasRouteData: Bool {
        return !self.routeData.isEmpty
    }
    
    var hasHeartRateData: Bool {
        return !self.heartRates.isEmpty
    }
    
    var pauseRanges: [ClosedRange<TimeInterval>] {
        let pauseEvents = self.workoutEvents.filter { (event) -> Bool in
            [.autoPause, .pause].contains(event.type)
        }
        var resumeEvents = self.workoutEvents.filter { (event) -> Bool in
            [.autoResume, .resume].contains(event.type)
        }
        var pauseRanges: [ClosedRange<TimeInterval>] = []
        func interval(_ date: Date) -> TimeInterval {
            return date.distance(to: self.startDate.value)
        }
        for pauseEvent in pauseEvents {
            let pauseInterval = interval(pauseEvent.startDate.value)
            
            let endInterval: TimeInterval = {
                if !resumeEvents.isEmpty {
                    let resumeEvent = resumeEvents.removeFirst()
                    return interval(resumeEvent.startDate.value)
                } else {
                    return interval(self.endDate.value)
                }
            }()
            
            guard pauseInterval < endInterval else {
                continue
            }
            
            let range = pauseInterval...endInterval
            
            pauseRanges.append(range)
        }
        return pauseRanges
    }
    
    var description: String {
        
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter.roundingIncrement = 2
        measurementFormatter.unitOptions = .naturalScale
        
        let distance = CustomMeasurementFormatting.string(forMeasurement: NSMeasurement(doubleValue: self.distance.value, unit: UnitLength.meters), type: .distance, rounding: .twoDigits)
        let duration = CustomMeasurementFormatting.string(forMeasurement: NSMeasurement(doubleValue: self.endDate.value.distance(to: self.startDate.value), unit: UnitDuration.seconds), type: .time, rounding: .twoDigits)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        let start = dateFormatter.string(from: startDate.value)
        let end = dateFormatter.string(from: endDate.value)
        
        guard let energyBurned = self.burnedEnergy.value else {
            return "Workout(type: \(type.debugDescription), start: \(start), end: \(end), distance: \(distance), duration: \(duration))"
        }
        
        let energy = CustomMeasurementFormatting.string(forMeasurement: NSMeasurement(doubleValue: energyBurned, unit: UnitEnergy.kilocalories), type: .energy, rounding: .wholeNumbers)
        
        return "Workout(type: \(type.debugDescription), start: \(start), end: \(end), distance: \(distance), duration: \(duration), energyBurned: \(energy))"
    }
    
    enum WorkoutType: CustomStringConvertible, CustomDebugStringConvertible, CaseIterable {
        case running, walking, cycling, skating, hiking, unknown

        static var allCases: [OutRunV3.Workout.WorkoutType] {
            return [.running, .walking, .cycling, skating, .hiking]
        }
        
        init(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .running
            case 1:
                self = .walking
            case 2:
                self = .cycling
            case 3:
                self = .skating
            case 4:
                self = .hiking
            default:
                self = .unknown
            }
        }
        
        init?(hkType: HKWorkoutActivityType) {
            switch hkType {
            case .running:
                self = .running
            case .walking:
                self = .walking
            case .cycling:
                self = .cycling
            case .skatingSports:
                self = .skating
            case .hiking:
                self = .hiking
            default:
                return nil
            }
        }
        
        var rawValue: Int {
            switch self {
            case .running:
                return 0
            case .walking:
                return 1
            case .cycling:
                return 2
            case .skating:
                return 3
            case .hiking:
                return 4
            case .unknown:
                return -1
            }
        }
        
        var description: String {
            switch self {
            case .running:
                return LS["Workout.Type.Running"]
            case .walking:
                return LS["Workout.Type.Walking"]
            case .cycling:
                return LS["Workout.Type.Cycling"]
            case .skating:
                return LS["Workout.Type.Skating"]
            case .hiking:
                return LS["Workout.Type.Hiking"]
            case .unknown:
                return LS["Workout.Type.Unknown"]
            }
        }
        
        var debugDescription: String {
            switch self {
            case .running:
                return "Running"
            case .walking:
                return "Walking"
            case .cycling:
                return "Cycling"
            case .skating:
                return "Skating"
            case .hiking:
                return "Hiking"
            case .unknown:
                return "Unknown"
            }
        }
        
        var METSpeedMultiplier: Double {
            switch self {
            case .running:
                return 1.035
            case .walking, .hiking:
                return 0.655
            case .cycling:
                return 0.450
            case .skating:
                return 0.560
            case .unknown:
                return 0
            }
        }
        
        var healthKitType: HKWorkoutActivityType {
            switch self {
            case .running:
                return .running
            case .walking:
                return .walking
            case .cycling:
                return .cycling
            case .skating:
                return .skatingSports
            case .hiking:
                return .hiking
            case .unknown:
                return .other
            }
        }
        
    }
    
}
