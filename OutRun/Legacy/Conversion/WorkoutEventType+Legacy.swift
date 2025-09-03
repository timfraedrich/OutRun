import OutRunCore

extension WorkoutEventType {
    
    init?(from legacyWorkoutEventType: LegacyWorkoutEventType) {
        switch legacyWorkoutEventType {
        case .pause, .autoPause, .resume, .autoResume:
            return nil
        case .lap:
            self = .lap
        case .marker:
            self = .marker
        case .segment:
            self = .segment
        case .unknown:
            self = .unknown
        }
    }
}
