import Foundation
@testable import OutRunDatabase

extension RawDataModelV2.Workout {
    
    init(from rawWorkout: RawWorkout) {
        self.init(
            uuid: rawWorkout.uuid,
            workoutType: rawWorkout.workoutType.rawValue,
            startDate: rawWorkout.startDate,
            endDate: rawWorkout.endDate ?? rawWorkout.startDate,
            distance: rawWorkout.distance,
            isRace: rawWorkout.isRace,
            isUserModified: rawWorkout.comment != nil,
            comment: rawWorkout.comment,
            burnedEnergy: rawWorkout.burnedEnergy ?? 0,
            healthKitUUID: nil,
            locations: rawWorkout.routeData.map { RawDataModelV2.RouteDataSample(from: $0) }
        )
    }
}