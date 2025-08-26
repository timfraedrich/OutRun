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
            insert(rawWorkout)
        }
        try modelContext.save()
        try await manager.deleteStorage()
    }
    
    // MARK: Internal
    
    private func insert(_ rawWorkout: RawWorkout) {
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
    }
    
    // MARK: Testing
    
    func fetchWorkouts() throws -> [RawWorkout] {
        try modelContext.fetch(FetchDescriptor<Workout>()).map(RawWorkout.init)
    }
}
