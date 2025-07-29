import Foundation
import HealthKit

public enum WorkoutType: CaseIterable, Codable, CustomDebugStringConvertible, Equatable, RawRepresentable {
    
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
    
    // TODO: Extract from database package
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
    
    // TODO: Extract from database package
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
    
    // TODO: Extract from database package
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
    
    // TODO: Extract from database package
    public var healthKitDistanceType: HKQuantityType? {
        switch self {
        case .running, .walking, .hiking: .init(.distanceWalkingRunning)
        case .cycling: .init(.distanceCycling)
        default: nil
        }
    }
}
