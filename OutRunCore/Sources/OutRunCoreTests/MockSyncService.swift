import Foundation
@testable import OutRunCore

actor MockSyncService: SyncService {

    let identifier: String
    var mode: SyncMode
    let relevantAttributes: Set<PartialKeyPath<Workout> & Sendable>

    private let insertResult: (id: String?, url: String?)
    private let updateResult: (id: String?, url: String?)
    private let insertError: Error?
    private let updateError: Error?
    private let deleteError: Error?

    private(set) var insertedWorkouts: [RawWorkout] = []
    private(set) var updatedWorkouts: [RawWorkout] = []
    private(set) var deletedWorkoutIds: [UUID] = []

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

    func initialize(with delegate: any SyncDelegate) async throws {}

    func insert(_ workout: RawWorkout) async throws -> (id: String?, url: String?) {
        if let error = insertError { throw error }
        insertedWorkouts.append(workout)
        return insertResult
    }

    func update(_ workout: RawWorkout) async throws -> (id: String?, url: String?) {
        if let error = updateError { throw error }
        updatedWorkouts.append(workout)
        return updateResult
    }

    func delete(workoutWith identifier: UUID) async throws {
        if let error = deleteError { throw error }
        deletedWorkoutIds.append(identifier)
    }
}
