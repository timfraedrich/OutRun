public enum WorkoutRecorderPermission: CaseIterable, Equatable, CustomStringConvertible, CustomDebugStringConvertible, Sendable {
    
    case location
    case motionAndFitness
    
    /// Indicated whether this permission is required for recording a workout.
    public var isRequired: Bool {
        switch self {
        case .location: true
        case .motionAndFitness: false
        }
    }
    
    public var description: String {
        switch self {
        case .location: .init(localized: "workout_recorder_permission_location", bundle: .module)
        case .motionAndFitness: .init(localized: "workout_recorder_permission_motion_and_fitness", bundle: .module)
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .location: "WorkoutRecorderPermission.location"
        case .motionAndFitness: "WorkoutRecorderPermission.motionAndFitness"
        }
    }
}
