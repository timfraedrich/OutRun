import Foundation

extension RawWorkout {
    
    init(from workout: RawDataModelV1.Workout) {
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(rawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: MigrationHelper.convertKcalToJoules(workout.burnedEnergy),
            steps: nil,
            isRace: false,
            name: nil,
            comment: nil,
            creationDate: workout.endDate,
            lastEditDate: workout.endDate,
            sourceService: .native,
            heartRates: [],
            routeData: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: [],
            workoutEvents: [],
            serviceMappings: MigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID)
        )
    }
    
    init(from workout: RawDataModelV2.Workout) {
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(rawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: MigrationHelper.convertKcalToJoules(workout.burnedEnergy),
            steps: nil,
            isRace: workout.isRace,
            name: nil,
            comment: workout.comment,
            creationDate: workout.endDate,
            lastEditDate: workout.endDate.addingTimeInterval(workout.isUserModified ? 0 : 1),
            sourceService: .native,
            heartRates: [],
            routeData: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: [],
            workoutEvents: [],
            serviceMappings: MigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID)
        )
    }
    
    init(from workout: RawDataModelV3.Workout) {
        let pauseEvents = workout.workoutEvents.compactMap { workoutEvent -> MigrationHelper.PauseEvent? in
            guard let pauseEventType = MigrationHelper.PauseEvent.PauseEventType(legacyEventType: .init(rawValue: workoutEvent.eventType))
            else { return nil }
            return .init(date: workoutEvent.startDate, type: pauseEventType)
        }
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(rawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: workout.burnedEnergy.map(MigrationHelper.convertKcalToJoules),
            steps: workout.steps,
            isRace: workout.isRace,
            name: nil,
            comment: workout.comment,
            creationDate: workout.endDate,
            lastEditDate: workout.endDate.addingTimeInterval(workout.isUserModified ? 0 : 1),
            sourceService: .native,
            heartRates: workout.heartRates.map(RawWorkoutHeartRateDataSample.init),
            routeData: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: MigrationHelper.calculatePauses(from: pauseEvents, workoutStart: workout.startDate, workoutEnd: workout.endDate),
            workoutEvents: workout.workoutEvents.compactMap(RawWorkoutEvent.init),
            serviceMappings: MigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID)
        )
    }
}
