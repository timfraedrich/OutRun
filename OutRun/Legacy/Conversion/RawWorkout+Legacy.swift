import Foundation
import OutRunCore

extension RawWorkout {
    
    init(from workout: LegacyRawDataModelV1.Workout) {
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(rawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: LegacyMigrationHelper.convertKcalToJoules(workout.burnedEnergy),
                    repetitions: nil,
            isRace: false,
            name: nil,
            comment: nil,
            creationDate: workout.endDate,
            lastEditDate: workout.endDate,
            source: .native,
            heartRates: [],
            route: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: [],
            events: [],
            serviceMappings: LegacyMigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID)
        )
    }
    
    init(from workout: LegacyRawDataModelV2.Workout) {
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(rawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: LegacyMigrationHelper.convertKcalToJoules(workout.burnedEnergy),
                    repetitions: nil,
            isRace: workout.isRace,
            name: nil,
            comment: workout.comment,
            creationDate: workout.endDate,
            lastEditDate: workout.endDate.addingTimeInterval(workout.isUserModified ? 1 : 0),
            source: .native,
            heartRates: [],
            route: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: [],
            events: [],
            serviceMappings: LegacyMigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID)
        )
    }
    
    init(from workout: LegacyRawDataModelV3.Workout) {
        let pauseEvents = workout.workoutEvents.compactMap { workoutEvent -> LegacyMigrationHelper.PauseEvent? in
            guard let pauseEventType = LegacyMigrationHelper.PauseEvent.PauseEventType(legacyEventType: .init(rawValue: workoutEvent.eventType))
            else { return nil }
            return .init(date: workoutEvent.startDate, type: pauseEventType)
        }
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(rawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: workout.burnedEnergy.map(LegacyMigrationHelper.convertKcalToJoules),
                    repetitions: workout.steps,
            isRace: workout.isRace,
            name: nil,
            comment: workout.comment,
            creationDate: workout.endDate,
            lastEditDate: workout.endDate.addingTimeInterval(workout.isUserModified ? 1 : 0),
            source: .native,
            heartRates: workout.heartRates.map(RawWorkoutHeartRateDataSample.init),
            route: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: LegacyMigrationHelper.calculatePauses(from: pauseEvents, workoutStart: workout.startDate, workoutEnd: workout.endDate),
            events: workout.workoutEvents.compactMap(RawWorkoutEvent.init),
            serviceMappings: LegacyMigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID)
        )
    }
}
