import SwiftData

class Database {
    
    let modelContainer: ModelContainer
    
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
        modelContainer = try ModelContainer(for: schema, migrationPlan: nil, configurations: config)
        
        guard CoreStoreManager<OutRunV3>.legacyStorageExists(for: legacyStorageFileName) else { return }
        let manager = try await CoreStoreManager<OutRunV3>(fileName: legacyStorageFileName)
        let legacyRawWorkouts = try await manager.extractAllWorkouts().map(RawWorkout.init)
        let context = ModelContext(modelContainer)
        for rawWorkout in legacyRawWorkouts {
            insert(rawWorkout, into: context)
        }
        try context.save()
        try await manager.deleteStorage()
    }
    
    func fetchWorkouts() throws -> [Workout] {
        try ModelContext(modelContainer).fetch(FetchDescriptor<Workout>())
    }
    
    func insert(_ workout: Workout) throws {
        let context = ModelContext(modelContainer)
        context.insert(workout)
        try context.save()
    }
    
    private func insert(_ rawWorkout: RawWorkout, into context: ModelContext) {
        let workout = Workout(from: rawWorkout)
        context.insert(workout)
        for rawRouteSample in rawWorkout.route {
            context.insert(WorkoutRouteDataSample(from: rawRouteSample, attachTo: workout))
        }
        for rawHeartRateSample in rawWorkout.heartRates {
            context.insert(WorkoutHeartRateDataSample(from: rawHeartRateSample, attachTo: workout))
        }
        for rawPause in rawWorkout.pauses {
            context.insert(WorkoutPause(from: rawPause, attachTo: workout))
        }
        for rawEvent in rawWorkout.events {
            context.insert(WorkoutEvent(from: rawEvent, attachTo: workout))
        }
        for rawServiceMapping in rawWorkout.serviceMappings {
            context.insert(WorkoutServiceMapping(from: rawServiceMapping, attachTo: workout))
        }
    }
}
