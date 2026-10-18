//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import HealthKit

public enum WorkoutType: CaseIterable, Codable, CustomDebugStringConvertible, CustomStringConvertible, Hashable, RawRepresentable, Sendable {
    
    case running
    case walking
    case cycling
    case skating
    case hiking
    case unknown(rawValue: String)
    
    public static var allCases: [WorkoutType] { [.running, .walking, .cycling, .skating, .hiking] }
    
    public init(rawValue: String) {
        self = switch rawValue {
        case "running": .running
        case "walking": .walking
        case "cycling": .cycling
        case "skating": .skating
        case "hiking": .hiking
        default: .unknown(rawValue: rawValue)
        }
    }
    
    /// Initializes from the integer raw values used by the legacy OutRun data models.
    public init(legacyRawValue: Int) {
        self = switch legacyRawValue {
        case 0: .running
        case 1: .walking
        case 2: .cycling
        case 3: .skating
        case 4: .hiking
        default: .unknown(rawValue: "unknown_\(legacyRawValue)")
        }
    }
    
    public init?(hkType: HKWorkoutActivityType) {
        switch hkType {
        case .running: self = .running
        case .walking: self = .walking
        case .cycling: self = .cycling
        case .skatingSports: self = .skating
        case .hiking: self = .hiking
        default: return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .running: "running"
        case .walking: "walking"
        case .cycling: "cycling"
        case .skating: "skating"
        case .hiking: "hiking"
        case .unknown(let rawValue): rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .running: .init(localized: "workout_type_running", bundle: .module)
        case .walking: .init(localized: "workout_type_walking", bundle: .module)
        case .cycling: .init(localized: "workout_type_cycling", bundle: .module)
        case .skating: .init(localized: "workout_type_skating", bundle: .module)
        case .hiking: .init(localized: "workout_type_hiking", bundle: .module)
        case .unknown: .init(localized: "workout_type_unknown", bundle: .module)
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .running: "WorkoutType.running"
        case .walking: "WorkoutType.walking"
        case .cycling: "WorkoutType.cycling"
        case .skating: "WorkoutType.skating"
        case .hiking: "WorkoutType.hiking"
        case .unknown(let rawValue): "WorkoutType.unknown(\(rawValue))"
        }
    }
    
    // TODO: Revisit values
    public var METSpeedMultiplier: Double {
        switch self {
        case .running: 1.035
        case .walking, .hiking: 0.655
        case .cycling: 0.450
        case .skating: 0.560
        case .unknown: 0
        }
    }
    
    public var healthKitType: HKWorkoutActivityType {
        switch self {
        case .running: .running
        case .walking: .walking
        case .cycling: .cycling
        case .skating: .skatingSports
        case .hiking: .hiking
        case .unknown: .other
        }
    }
    
    var healthKitDistanceType: HealthSyncService.SupportedHealthKitType? {
        switch self {
        case .running, .walking, .hiking: .sampleDistanceWalkingRunning
        case .cycling: .sampleDistanceCycling
        case .skating: .sampleDistanceSkatingSports
        default: nil
        }
    }
    
    var healthKitRepetitionsType: HealthSyncService.SupportedHealthKitType? {
        switch self {
        case .running, .walking, .hiking: .sampleStepCount
        default: nil
        }
    }
    
    public var supportsAutomaticPause: Bool {
        automaticPauseThresholds != nil
    }
    
    public var automaticPauseThresholds: (pauseThreshold: Double, resumeThreshold: Double)? {
        let kilometersPerHour = Calculation.calculateBaseSpeedUnitValue(kilometersPerHour:)
        return switch self {
        case .running: (kilometersPerHour(4), kilometersPerHour(5))
        case .walking: (kilometersPerHour(1.5), kilometersPerHour(2))
        case .cycling: (kilometersPerHour(9), kilometersPerHour(12))
        case .hiking, .skating, .unknown: nil
        }
    }
}
