import Foundation
import HealthKit

public enum WorkoutEventType: Codable, CustomDebugStringConvertible, Equatable, RawRepresentable, Sendable {
    
    case lap
    case marker
    case segment
    case unknown
    
    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .lap
        case 1: self = .marker
        case 2: self = .segment
        default: self = .unknown
        }
    }
    
    public init(rawValue: Int?) {
        self.init(rawValue: rawValue ?? -1)
    }
    
    // TODO: Extract from database package
    public init?(healthType: HKWorkoutEventType) {
        switch healthType {
        case .lap: self = .lap
        case .marker: self = .marker
        case .segment: self = .segment
        default: return nil
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .lap: 0
        case .marker: 1
        case .segment: 2
        case .unknown: -1
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .lap: "WorkoutEventType.lap"
        case .marker: "WorkoutEventType.marker"
        case .segment: "WorkoutEventType.segment"
        case .unknown: "WorkoutEventType.unknown"
        }
    }
    
    // TODO: Extract from database package
    public var healthKitType: HKWorkoutEventType? {
        switch self {
        case .lap: .lap
        case .marker: .marker
        case .segment: .segment
        case .unknown: nil
        }
    }
}
