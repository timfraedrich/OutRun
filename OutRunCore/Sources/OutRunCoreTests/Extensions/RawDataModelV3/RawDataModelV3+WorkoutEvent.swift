import Foundation
@testable import OutRunDatabase

extension RawDataModelV3.WorkoutEvent {
    
    init(from rawEvent: RawWorkoutEvent) {
        self.init(
            uuid: rawEvent.uuid,
            eventType: rawEvent.eventType.rawValue,
            startDate: rawEvent.timestamp,
            endDate: rawEvent.timestamp
        )
    }
}