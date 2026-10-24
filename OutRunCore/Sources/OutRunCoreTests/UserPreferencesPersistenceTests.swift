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
import Testing

@Suite("User Preferences Persistence Tests", .serialized)
@MainActor
struct UserPreferencesPersistenceTests {

    @Test("Changed Preferences Are Persisted")
    func changedPreferencesArePersisted() async throws {
        let core = OutRunCore(config: .init(isStoredInMemoryOnly: true, recordableDataTypes: [.location]))
        await core.wait(for: .needsSetup)
        try await core.setup(for: RawUser(name: "Test", preferences: [:], creationDate: .now))
        guard let database = core.database, let userPreferences = core.userPreferences else { throw "Core was not initialized." }

        userPreferences.pauseAutomatically = false
        userPreferences.distanceUnit = .miles
        let expectedPreferences = userPreferences.preferences

        let persistedUser = try await waitForPersistedUser(in: database) { $0.preferences == expectedPreferences }
        let persistedPreferences = UserPreferences(preferences: persistedUser.preferences)
        #expect(persistedPreferences.pauseAutomatically == false)
        #expect(persistedPreferences.distanceUnit == .miles)
    }

    // MARK: Helper Methods

    private func waitForPersistedUser(
        in database: Database,
        timeout: Duration = .seconds(5),
        where predicate: @escaping @Sendable (RawUser) -> Bool
    ) async throws -> RawUser {
        let (userStream, streamTask) = try await database.userStream()
        defer { streamTask.cancel() }
        return try await withThrowingTaskGroup(of: RawUser.self) { group in
            group.addTask {
                for try await user in userStream {
                    if let user, predicate(user) { return user }
                }
                throw "User stream finished without matching user."
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw "Timed out waiting for persisted user preferences."
            }
            defer { group.cancelAll() }
            guard let user = try await group.next() else { throw "No result." }
            return user
        }
    }
}
