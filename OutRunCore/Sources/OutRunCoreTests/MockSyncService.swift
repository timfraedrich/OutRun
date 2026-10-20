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
    private(set) var isAuthorizedToSyncOutward: Bool

    private var upsertResult: (id: String?, url: String?)
    private var upsertError: Error?
    private var deleteError: Error?
    private var hasNewerVersion: Bool
    private var serviceWorkouts: [String: RawWorkout]

    private(set) var upsertedWorkouts: [UUID:RawWorkout] = [:]
    private(set) var lastReplacingNewerVersion: Bool?
    private(set) var deletedWorkoutIds: Set<UUID> = []
    private(set) var initialized = false

    init(
        identifier: String = "mock",
        mode: SyncMode = .enabled,
        relevantAttributes: Set<PartialKeyPath<Workout> & Sendable> = [],
        isAuthorizedToSyncOutward: Bool = true,
        upsertResult: (id: String?, url: String?) = ("mock-external-id", "https://mock.example"),
        upsertError: Error? = nil,
        deleteError: Error? = nil,
        hasNewerVersion: Bool = false,
        serviceWorkouts: [String: RawWorkout] = [:]
    ) {
        self.identifier = identifier
        self.outwardSyncMode = mode
        self.relevantAttributes = relevantAttributes
        self.isAuthorizedToSyncOutward = isAuthorizedToSyncOutward
        self.upsertResult = upsertResult
        self.upsertError = upsertError
        self.deleteError = deleteError
        self.hasNewerVersion = hasNewerVersion
        self.serviceWorkouts = serviceWorkouts
    }

    func initialize(with delegate: any SyncDelegate) async throws {
        initialized = true
    }
    
    func deinitialize() async {
        initialized = false
    }

    func upsert(_ workout: RawWorkout, replacingNewerVersion: Bool) async throws -> (id: String?, url: String?) {
        lastReplacingNewerVersion = replacingNewerVersion
        if let error = upsertError { throw error }
        if hasNewerVersion, !replacingNewerVersion { throw SyncError.conflict }
        upsertedWorkouts[workout.id] = workout
        return upsertResult
    }

    func fetchWorkout(for mapping: RawSyncServiceMapping) async throws -> RawWorkout {
        guard let externalId = mapping.externalId, let workout = serviceWorkouts[externalId] else { throw SyncError.workoutNotFoundOnService }
        return workout
    }

    func delete(workoutWith identifier: UUID) async throws {
        if let error = deleteError { throw error }
        deletedWorkoutIds.insert(identifier)
    }
    
    func reset() {
        upsertedWorkouts = [:]
        deletedWorkoutIds = []
    }

    func setAuthorizedToSyncOutward(_ isAuthorized: Bool) {
        isAuthorizedToSyncOutward = isAuthorized
    }

    func clearError() {
        upsertError = nil
        deleteError = nil
    }
}
