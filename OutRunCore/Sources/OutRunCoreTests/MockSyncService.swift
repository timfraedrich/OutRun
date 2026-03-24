import Foundation
@testable import OutRunCore

actor MockSyncService: SyncService {

    let identifier: String
    var mode: SyncMode
    let relevantAttributes: Set<PartialKeyPath<Workout> & Sendable>

    private var upsertResult: (id: String?, url: String?)
    private var upsertError: Error?
    private var deleteError: Error?

    private(set) var upsertedWorkouts: [UUID:RawWorkout] = [:]
    private(set) var deletedWorkoutIds: Set<UUID> = []
    private(set) var initialized = false

    init(
        identifier: String = "mock",
        mode: SyncMode = .enabled,
        relevantAttributes: Set<PartialKeyPath<Workout> & Sendable> = [],
        upsertResult: (id: String?, url: String?) = ("mock-external-id", "https://mock.example"),
        upsertError: Error? = nil,
        deleteError: Error? = nil
    ) {
        self.identifier = identifier
        self.mode = mode
        self.relevantAttributes = relevantAttributes
        self.upsertResult = upsertResult
        self.upsertError = upsertError
        self.deleteError = deleteError
    }

    func initialize(with delegate: any SyncDelegate) async throws {
        initialized = true
    }
    
    func deinitialize() async {
        initialized = false
    }

    func upsert(_ workout: RawWorkout) async throws -> (id: String?, url: String?) {
        if let error = upsertError { throw error }
        upsertedWorkouts[workout.id] = workout
        return upsertResult
    }

    func delete(workoutWith identifier: UUID) async throws {
        if let error = deleteError { throw error }
        deletedWorkoutIds.insert(identifier)
    }

    // Helper methods for testing
    func reset() {
        upsertedWorkouts = [:]
        deletedWorkoutIds = []
    }

    func clearError() {
        upsertError = nil
        deleteError = nil
    }
}
