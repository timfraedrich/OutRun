import Foundation
@testable import OutRunDatabase

extension RawDataModelV1.Workout {
    
    init(from rawWorkout: RawWorkout) {
        self.init(
            uuid: rawWorkout.uuid,
            workoutType: rawWorkout.workoutType.rawValue,
            startDate: rawWorkout.startDate,
            endDate: rawWorkout.endDate ?? rawWorkout.startDate,
            distance: rawWorkout.distance,
            burnedEnergy: rawWorkout.burnedEnergy ?? 0,
            healthKitUUID: nil,
            locations: rawWorkout.routeData.map { RawDataModelV1.RouteDataSample(from: $0) }
        )
    }
}