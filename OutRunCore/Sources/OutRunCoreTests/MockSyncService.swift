import Foundation
@testable import OutRunCore

actor MockSyncService: SyncService {

    let identifier: String
    var mode: SyncMode
    let relevantAttributes: Set<PartialKeyPath<Workout> & Sendable>

    private var insertResult: (id: String?, url: String?)
    private var updateResult: (id: String?, url: String?)
    private var insertError: Error?
    private var updateError: Error?
    private var deleteError: Error?

    private(set) var insertedWorkouts: [UUID:RawWorkout] = [:]
    private(set) var updatedWorkouts: [UUID:RawWorkout] = [:]
    private(set) var deletedWorkoutIds: Set<UUID> = []
    private(set) var initializeCalled = false

    init(
        identifier: String = "mock",
        mode: SyncMode = .enabled,
        relevantAttributes: Set<PartialKeyPath<Workout> & Sendable> = [],
        insertResult: (id: String?, url: String?) = ("mock-external-id", "https://mock.example"),
        updateResult: (id: String?, url: String?) = ("mock-external-id", "https://mock.example"),
        insertError: Error? = nil,
        updateError: Error? = nil,
        deleteError: Error? = nil
    ) {
        self.identifier = identifier
        self.mode = mode
        self.relevantAttributes = relevantAttributes
        self.insertResult = insertResult
        self.updateResult = updateResult
        self.insertError = insertError
        self.updateError = updateError
        self.deleteError = deleteError
    }

    func initialize(with delegate: any SyncDelegate) async throws {
        initializeCalled = true
    }

    func insert(_ workout: RawWorkout) async throws -> (id: String?, url: String?) {
        if let error = insertError { throw error }
        insertedWorkouts[workout.id] = workout
        return insertResult
    }

    func update(_ workout: RawWorkout) async throws -> (id: String?, url: String?) {
        if let error = updateError { throw error }
        updatedWorkouts[workout.id] = workout
        return updateResult
    }

    func delete(workoutWith identifier: UUID) async throws {
        if let error = deleteError { throw error }
        deletedWorkoutIds.insert(identifier)
    }

    // Helper methods for testing
    func reset() {
        insertedWorkouts = [:]
        updatedWorkouts = [:]
        deletedWorkoutIds = []
    }

    func clearError() {
        insertError = nil
        updateError = nil
        deleteError = nil
    }
}
