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
import HealthKit

/// Protocol that exposes synchronization functionality of an external service to receive data from the core.
public protocol SyncService: AnyObject, Sendable {
    
    /// The identifier of the external service.
    var identifier: String { get }
    
    /// A set of Workout instance attributes, whose change should trigger a synchronisation. If left empty the insertion and deletion of a
    /// Workout object will still trigger synchronization events.
    var relevantAttributes: Set<PartialKeyPath<Workout> & Sendable> { get }
    
    /// The SyncMode to be used for changes syncing outward (from the core to the external service, implementing the protocol).
    /// - note: This variable should only be assumed valid, while the service is initialized.
    var outwardSyncMode: SyncMode { get async }
    
    /// Initializes the service with a sync delegate.
    func initialize(with delegate: any SyncDelegate) async throws
    
    /// Deinitializes the service.
    func deinitialize() async
    
    /// Called when a workout was created or updated and should be synced to the service.
    /// - returns: An identifier or URL to the workout for the external service.
    /// - note: This function may be called multiple times with the same workout data. If the exact workout data was previously synced, the
    /// request can just be ignored, but the correct id or url should still be returned.
    func upsert(_ workout: RawWorkout) async throws -> (id: String?, url: String?)
    
    /// Called when a workout was deleted and should be synced to the service.
    /// - note: This function may be called for identifiers whose corresponding workouts were never synced to the service or already
    /// deleted. This case should be treated as success with no error being thrown.
    func delete(workoutWith identifier: UUID) async throws
}
