import Foundation
import HealthKit

public enum WorkoutType: CaseIterable, Codable, CustomDebugStringConvertible, CustomStringConvertible, Equatable, RawRepresentable, Sendable {
    
    case running
    case walking
    case cycling
    case skating
    case hiking
    case unknown
    
    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .running
        case 1: self = .walking
        case 2: self = .cycling
        case 3: self = .skating
        case 4: self = .hiking
        default: self = .unknown
        }
    }
    
    public init(rawValue: Int?) {
        self.init(rawValue: rawValue ?? -1)
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
    
    public var rawValue: Int {
        switch self {
        case .running: 0
        case .walking: 1
        case .cycling: 2
        case .skating: 3
        case .hiking: 4
        case .unknown: -1
        }
    }
    
    public var description: String {
        switch self {
        case .running: R.string.localizable.workout_type_running()
        case .walking: R.string.localizable.workout_type_walking()
        case .cycling: R.string.localizable.workout_type_cycling()
        case .skating: R.string.localizable.workout_type_skating()
        case .hiking: R.string.localizable.workout_type_hiking()
        case .unknown: R.string.localizable.workout_type_unknown()
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .running: "WorkoutType.running"
        case .walking: "WorkoutType.walking"
        case .cycling: "WorkoutType.cycling"
        case .skating: "WorkoutType.skating"
        case .hiking: "WorkoutType.hiking"
        case .unknown: "WorkoutType.unknown"
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
    
    public var healthKitDistanceType: HKQuantityType? {
        switch self {
        case .running, .walking, .hiking: .init(.distanceWalkingRunning)
        case .cycling: .init(.distanceCycling)
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
