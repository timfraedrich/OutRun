import Foundation
@testable import OutRunDatabase

extension RawDataModelV3.Workout {
    
    init(from rawWorkout: RawWorkout) {
        self.init(
            uuid: rawWorkout.uuid,
            workoutType: rawWorkout.workoutType.rawValue,
            startDate: rawWorkout.startDate,
            endDate: rawWorkout.endDate ?? rawWorkout.startDate,
            distance: rawWorkout.distance,
            steps: rawWorkout.steps,
            isRace: rawWorkout.isRace,
            isUserModified: rawWorkout.comment != nil,
            comment: rawWorkout.comment,
            burnedEnergy: rawWorkout.burnedEnergy,
            healthKitUUID: nil,
            workoutEvents: rawWorkout.workoutEvents.map { RawDataModelV3.WorkoutEvent(from: $0) },
            locations: rawWorkout.routeData.map { RawDataModelV3.WorkoutRouteDataSample(from: $0) },
            heartRates: rawWorkout.heartRates.map { RawDataModelV3.WorkoutHeartRateDataSample(from: $0) }
        )
    }
}