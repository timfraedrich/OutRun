import Foundation

extension RawWorkoutEvent {
    
    init?(from workoutEvent: RawDataModelV3.WorkoutEvent) {
        guard let type = WorkoutEventType(from: .init(rawValue: workoutEvent.eventType)) else { return nil }
        self.init(type: WorkoutEventType(rawValue: workoutEvent.eventType), timestamp: workoutEvent.startDate)
    }
}
