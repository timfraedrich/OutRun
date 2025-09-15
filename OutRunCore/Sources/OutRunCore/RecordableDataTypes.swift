import Foundation

/// An OptionSet of data that can be recorded during a workout.
public struct RecordableDataTypes: OptionSet, Sendable, Hashable {
    
    public let rawValue: Int
    
    public static let location = RecordableDataTypes(rawValue: 1 << 0)
    public static let preciseAltitude = RecordableDataTypes(rawValue: 1 << 1)
    public static let steps = RecordableDataTypes(rawValue: 1 << 2)
    
    public static let all: RecordableDataTypes = [.location, .preciseAltitude, .steps]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
