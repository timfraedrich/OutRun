import Foundation
import HealthKit

public enum WorkoutEventType: Codable, CustomDebugStringConvertible, Hashable, RawRepresentable, Sendable {
    
    case lap
    case marker
    case segment
    case unknown(rawValue: Int)
    
    public init(rawValue: Int) {
        self = switch rawValue {
        case 0: .lap
        case 1: .marker
        case 2: .segment
        default: .unknown(rawValue: rawValue)
        }
    }
    
    public init(rawValue: Int?) {
        self.init(rawValue: rawValue ?? -1)
    }
    
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
        case .unknown(let rawValue): rawValue
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .lap: "WorkoutEventType.lap"
        case .marker: "WorkoutEventType.marker"
        case .segment: "WorkoutEventType.segment"
        case .unknown(let rawValue): "WorkoutEventType.unknown(\(rawValue))"
        }
    }
    
    public var healthKitType: HKWorkoutEventType? {
        switch self {
        case .lap: .lap
        case .marker: .marker
        case .segment: .segment
        case .unknown: nil
        }
    }
}
