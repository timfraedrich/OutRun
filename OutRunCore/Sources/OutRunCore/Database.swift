import Combine
import Foundation
import SwiftData

actor Database: ModelActor {
    
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor
    
    init(modelContainer: ModelContainer, legacyStorageFileName: String? = nil) async throws {
        self.modelContainer = modelContainer
        let modelContext = ModelContext(modelContainer)
        modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        
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
    
    /// Initializes a workout for live recording.
    /// - returns: The identifier of the initialized workout.
    /// - throws: Throws if saving the workout fails.
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
    
    /// Continues a workout that has previously been finished.
    /// - returns: The current state of the workout to restore the recording process.
    /// - throws: Throws if the workout cannot be found, is not yet finished or saving changes fails.
    /// - note: A user initiated pause from the current endDate to the continueDate is added to the workout to indicate that the user
    /// interrupted the recording process. This can lead to a very long pause in the workout. For UX reasons the user should only be able to
    /// continue very recently finished workouts.
    func continueWorkout(with identifier: UUID, continueDate: Date) throws -> RawWorkout {
        let workout = try fetchWorkout(with: identifier)
        guard let endDate = workout.endDate else { throw DatabaseError.workoutNotFinished }
        workout.endDate = nil
        modelContext.insert(WorkoutPause(startDate: endDate, endDate: continueDate, userInitiated: true, workout: workout))
        workout.lastEditDate = .now
        try modelContext.save()
        return RawWorkout(workout: workout)
    }
    
    /// Adds a route sample to a workout currently being recorded.
    /// - throws: Throws if the workout cannot be found, is already finished or saving it fails.
    func addRouteSample(
        _ sample: RawWorkoutRouteDataSample,
        toWorkoutWith identifier: UUID,
        addedDistance: Double,
        updatedEnergy: Double? = nil,
        updatedRepetitions: Int? = nil
    ) throws {
        let workout = try fetchWorkout(with: identifier)
        guard workout.endDate == nil else { throw DatabaseError.workoutAlreadyFinished }
        modelContext.insert(WorkoutRouteDataSample(from: sample, attachTo: workout))
        workout.distance += addedDistance
        if let updatedEnergy = updatedEnergy { workout.energy = updatedEnergy }
        if let updatedRepetitions = updatedRepetitions { workout.repetitions = updatedRepetitions }
        workout.lastEditDate = .now
        try modelContext.save()
    }
    
    /// Adds a pause to a workout currently being recorded.
    /// - throws: Throws if the workout cannot be found, is already finished or saving it fails.
    func addPause(_ pause: RawWorkoutPause, toWorkoutWith identifier: UUID) throws {
        let workout = try fetchWorkout(with: identifier)
        guard workout.endDate == nil else { throw DatabaseError.workoutAlreadyFinished }
        modelContext.insert(WorkoutPause(from: pause, attachTo: workout))
        workout.lastEditDate = .now
        try modelContext.save()
    }
    
    /// Finalizes a workout currently being recorded and saves or discards it based on the recorded distance.
    /// - returns: A `RawWorkout` representing the final recorded workout if the recorded distance is larger than zero, `nil` otherwise.
    /// - throws: Throws if the workout cannot be found, is already finished or saving it fails.
    func finalizeWorkout(with identifier: UUID, endDate: Date) throws -> RawWorkout? {
        let workout = try fetchWorkout(with: identifier)
        guard workout.endDate == nil else { throw DatabaseError.workoutAlreadyFinished }
        if workout.distance > .zero {
            workout.endDate = endDate
            workout.lastEditDate = .now
            try modelContext.save()
            return RawWorkout(workout: workout)
        } else {
            modelContext.delete(workout)
            try modelContext.save()
            return nil
        }
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
    
    init(
        isStoredInMemoryOnly: Bool = false,
        groupContainer: ModelConfiguration.GroupContainer = .automatic,
        legacyStorageFileName: String? = nil
    ) async throws {
        try await self.init(
            modelContainer: try Self.modelContainer(isStoredInMemoryOnly: isStoredInMemoryOnly, groupContainer: groupContainer),
            legacyStorageFileName: legacyStorageFileName
        )
    }
    
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
        /// Functions meant for manipulation during recording were called after a workout had already been finished.
        case workoutAlreadyFinished
        
        var debugDescription: String {
            switch self {
            case .objectNotFound: ".objectNotFound"
            case .workoutNotFinished: ".workoutNotFinished"
            case .workoutAlreadyFinished: ".workoutAlreadyFinished"
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .objectNotFound: R.string.localizable.database_error_object_not_found()
            case .workoutNotFinished: R.string.localizable.database_error_workout_not_finished()
            case .workoutAlreadyFinished: R.string.localizable.database_error_workout_already_finished()
            }
        }
    }
    
    // MARK: Static
    
    static func modelContainer(
        isStoredInMemoryOnly: Bool = false,
        groupContainer: ModelConfiguration.GroupContainer = .automatic
    ) throws -> ModelContainer {
        // If migrations get added, prevent extensions to automatically migrate to avoid crashes.
        // See https://developer.apple.com/forums/thread/773637?answerId=824240022#824240022 to handle this properly.
        let schema = Schema(versionedSchema: ModelSchema.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: groupContainer,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, migrationPlan: nil, configurations: config)
    }
}
