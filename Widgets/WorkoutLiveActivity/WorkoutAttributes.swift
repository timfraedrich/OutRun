import ActivityKit
import Foundation
import OutRunCore

public struct WorkoutAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable, Sendable {
        public var type: WorkoutType
        public var isPaused: Bool
        public var duration: DynamicTimeInterval
        public var distance: Measurement<UnitLength>
        /// The preferences of the user recording the workout, used to display metrics in the preferred units.
        public var preferences: RawPreferences

        public init(
            type: WorkoutType,
            isPaused: Bool,
            duration: DynamicTimeInterval,
            distance: Measurement<UnitLength>,
            preferences: RawPreferences
        ) {
            self.type = type
            self.isPaused = isPaused
            self.duration = duration
            self.distance = distance
            self.preferences = preferences
        }
    }

    public init() {}
}
