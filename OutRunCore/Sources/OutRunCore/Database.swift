import Foundation
import SwiftData

@ModelActor
actor Database {
    
    init(
        isStoredInMemoryOnly: Bool = false,
        groupContainer: ModelConfiguration.GroupContainer = .automatic,
        legacyStorageFileName: String? = nil
    ) async throws {
        
        let schema = Schema(versionedSchema: ModelSchema.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: groupContainer,
            cloudKitDatabase: .none
        )
        self.init(modelContainer: try ModelContainer(for: schema, migrationPlan: nil, configurations: config))
        
        guard LegacyDatabase<LegacyDataModelV3>.legacyStorageExists(for: legacyStorageFileName) else { return }
        let manager = try await LegacyDatabase<LegacyDataModelV3>(fileName: legacyStorageFileName)
        let legacyRawWorkouts = try await manager.extractAllWorkouts().map(RawWorkout.init)
        for rawWorkout in legacyRawWorkouts {
            try insert(rawWorkout)
        }
        try modelContext.save()
        try await manager.deleteStorage()
    }
    
    // MARK: Recording
    
    func initializeWorkout(with type: WorkoutType, startDate: Date) throws -> UUID {
        let workout = Workout(
            type: type,
            distance: .zero,
            startDate: startDate,
            endDate: nil,
            energy: nil,
            repetitions: nil,
            isRace: false,
            name: nil,
            comment: nil,
            creationDate: .now,
            sourceService: .native
        )
        modelContext.insert(workout)
        try modelContext.save()
        return workout.id
    }
    
    func continueWorkout(with identifier: UUID, continueDate: Date) throws -> RawWorkout {
        let workout = try fetchWorkout(with: identifier)
        guard let endDate = workout.endDate else { throw DatabaseError.workoutNotFinished }
        workout.endDate = nil
        modelContext.insert(WorkoutPause(startDate: endDate, endDate: continueDate, userInitiated: true, workout: workout))
        workout.lastEditDate = .now
        try modelContext.save()
        return RawWorkout(workout: workout)
    }
    
    func addRouteSample(
        _ sample: RawWorkoutRouteDataSample,
        toWorkoutWith identifier: UUID,
        addedDistance: Double,
        updatedEnergy: Double? = nil,
        updatedRepetitions: Int? = nil
    ) throws {
        let workout = try fetchWorkout(with: identifier)
        modelContext.insert(WorkoutRouteDataSample(from: sample, attachTo: workout))
        workout.distance += addedDistance
        if let updatedEnergy = updatedEnergy { workout.energy = updatedEnergy }
        if let updatedRepetitions = updatedRepetitions { workout.repetitions = updatedRepetitions }
        workout.lastEditDate = .now
        try modelContext.save()
    }
    
    func addPause(_ pause: RawWorkoutPause, toWorkoutWith identifier: UUID) throws {
        let workout = try fetchWorkout(with: identifier)
        modelContext.insert(WorkoutPause(from: pause, attachTo: workout))
        workout.lastEditDate = .now
        try modelContext.save()
    }
    
    func finalizeWorkout(with identifier: UUID, endDate: Date) throws -> RawWorkout {
        let workout = try fetchWorkout(with: identifier)
        workout.endDate = endDate
        workout.lastEditDate = .now
        try modelContext.save()
        return RawWorkout(workout: workout)
    }
    
    // MARK: Internal
    
    private func fetchWorkout(with identifier: UUID) throws -> Workout {
        let descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == identifier })
        guard let workout = try modelContext.fetch(descriptor).first else {
            throw DatabaseError.objectNotFound
        }
        return workout
    }
    
    // MARK: Testing
    
    func insert(_ rawWorkout: RawWorkout) throws {
        let workout = Workout(from: rawWorkout)
        modelContext.insert(workout)
        for rawRouteSample in rawWorkout.route {
            modelContext.insert(WorkoutRouteDataSample(from: rawRouteSample, attachTo: workout))
        }
        for rawHeartRateSample in rawWorkout.heartRates {
            modelContext.insert(WorkoutHeartRateDataSample(from: rawHeartRateSample, attachTo: workout))
        }
        for rawPause in rawWorkout.pauses {
            modelContext.insert(WorkoutPause(from: rawPause, attachTo: workout))
        }
        for rawEvent in rawWorkout.events {
            modelContext.insert(WorkoutEvent(from: rawEvent, attachTo: workout))
        }
        for rawServiceMapping in rawWorkout.serviceMappings {
            modelContext.insert(WorkoutServiceMapping(from: rawServiceMapping, attachTo: workout))
        }
        try modelContext.save()
    }
    
    func fetchWorkouts() throws -> [RawWorkout] {
        try modelContext.fetch(FetchDescriptor<Workout>()).map(RawWorkout.init)
    }
    
    // MARK: DatabaseError
    
    enum DatabaseError: LocalizedError, CustomDebugStringConvertible {
        
        /// The object was not found in the database.
        case objectNotFound
        /// The function ``Database/continueWorkout(with:continueDate:)`` was called on a workout that has not been finished.
        case workoutNotFinished
        
        var debugDescription: String {
            switch self {
            case .objectNotFound: ".objectNotFound"
            case .workoutNotFinished: ".workoutNotFinished"
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .objectNotFound: R.string.localizable.database_error_object_not_found()
            case .workoutNotFinished: R.string.localizable.database_error_workout_not_finished()
            }
        }
    }
}
