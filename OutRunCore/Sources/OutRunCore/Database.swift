import SwiftData

class Database {
    
    let modelContainer: ModelContainer
    
    init(isStoredInMemoryOnly: Bool = false, groupContainer: ModelConfiguration.GroupContainer = .automatic) async throws {
        let schema = Schema(versionedSchema: ModelSchema.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: groupContainer,
            cloudKitDatabase: .none
        )
        modelContainer = try ModelContainer(for: schema, migrationPlan: nil, configurations: config)
    }
    
    func insert(_ workout: Workout) throws {
        let context = ModelContext(modelContainer)
        context.insert(workout)
        try context.save()
    }
}
