//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation
@testable import OutRunCore

actor MockSyncService: SyncService {

    let identifier: String
    let outwardSyncMode: SyncMode
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
        self.outwardSyncMode = mode
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
    
    func reset() {
        upsertedWorkouts = [:]
        deletedWorkoutIds = []
    }

    func clearError() {
        upsertError = nil
        deleteError = nil
    }
}
