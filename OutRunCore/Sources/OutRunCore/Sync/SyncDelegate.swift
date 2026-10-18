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

/// Protocol that exposes synchronization functionality from an external service to the core.
public protocol SyncDelegate: AnyObject, Sendable {
    
    /// Called when a workout was created or updated and should be synced to the core.
    /// - returns: The identifier of the workout saved in the core.
    @discardableResult
    func upsert(_ workout: RawWorkout) async throws -> UUID
    
    /// Called when a workout was deleted and should be synced to the core.
    /// - parameter identifier: The identifier of the workout from the core.
    /// - parameter serviceIdentifier: The identifier of the service deleting the workout.
    /// - throws: Throws `SyncError.conflict` if the workout was not created by the service. The workout is kept in this case and its sync
    /// status for the service is set to ``WorkoutSyncStatus/conflict``.
    func delete(workoutWithIdentifier identifier: UUID, forServiceWith serviceIdentifier: String) async throws
    
    /// Called when a workout was deleted and should be synced to the core.
    /// - parameter externalIdentifier: The identifier of the workout from an external service.
    /// - note: The delegate will attempt to find the workout by locating a SyncServiceMapping that has the assigned id.
    /// - throws: Throws `SyncError.conflict` if the workout was not created by the service. The workout is kept in this case and its sync
    /// status for the service is set to ``WorkoutSyncStatus/conflict``.
    func delete(workoutWithExternalIdentifier externalIdentifier: String, forServiceWith serviceIdentifier: String) async throws
    
    /// Called when a workout was deleted and should be synced to the core.
    /// - parameter externalURL: The url to the workout from an external service.
    /// - note: The delegate will attempt to find the workout by locating a SyncServiceMapping that has the assigned id.
    /// - throws: Throws `SyncError.conflict` if the workout was not created by the service. The workout is kept in this case and its sync
    /// status for the service is set to ``WorkoutSyncStatus/conflict``.
    func delete(workoutWithExternalURL externalURL: String, forServiceWith serviceIdentifier: String) async throws
    
    /// Sets a value to the appropriate UserDefaults.
    func setDevicePreference(_ value: Any, for key: String)
    
    /// Retrives a value from the appropriate UserDefaults.
    func devicePreference(for key: String) -> Any?
}
