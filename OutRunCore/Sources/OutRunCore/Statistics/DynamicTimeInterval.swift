import Foundation

public enum DynamicTimeInterval: Hashable, Sendable, Codable {

    case constant(TimeInterval)
    case increasing(since: Date, offset: TimeInterval)
    
    public func timeInterval(for referenceDate: Date) -> TimeInterval {
        switch self {
        case .constant(let timeInterval):
            return timeInterval
        case .increasing(let startDate, let offset):
            guard referenceDate > startDate.addingTimeInterval(offset) else { return .zero }
            return startDate.addingTimeInterval(offset).distance(to: referenceDate)
        }
    }
}
