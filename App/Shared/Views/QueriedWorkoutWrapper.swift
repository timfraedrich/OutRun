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

import OutRunCore
import SwiftData
import SwiftUI

struct QueriedWorkoutWrapper<Content: View>: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(OutRunCore.self) private var core
    @State private var result: Result<RawWorkout, Error>?
    
    private let id: Workout.ID
    private let content: (any WorkoutProtocol) -> Content
    
    init(id: Workout.ID, @ViewBuilder content: @escaping (any WorkoutProtocol) -> Content) {
        self.id = id
        self.content = content
    }
    
    var body: some View {
        ZStack {
            switch result {
            case .success(let workout):
                content(workout)
            case .failure(let error):
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            case .none:
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
            }
        }
        .transition(.blurReplace)
        .animation(.default, value: result != nil)
        .task(id: id) { await observeWorkout() }
    }

    private func observeWorkout() async {
        let didSaveNotifications = NotificationCenter.default.notifications(named: ModelContext.didSave)
        var persistentModelID = await loadWorkout()
        for await notification in didSaveNotifications {
            if let persistentModelID, !notification.containsChanges(to: persistentModelID) { continue }
            persistentModelID = await loadWorkout()
        }
    }

    /// - Returns: The persistent identifier of the loaded workout, or `nil` if it could not be loaded.
    private func loadWorkout() async -> PersistentIdentifier? {
        let fetchResult = await modelContext.container.fetchRawWorkout(with: id)
        result = fetchResult.map(\.workout)
        return try? fetchResult.get().persistentModelID
    }
}

private struct WorkoutNotFoundError: LocalizedError {
    var errorDescription: String? {
        .init(localized: "error_workout_not_found")
    }
}

private extension ModelContainer {

    @concurrent
    func fetchRawWorkout(with id: Workout.ID) async -> Result<(workout: RawWorkout, persistentModelID: PersistentIdentifier), Error> {
        do {
            var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id })
            descriptor.relationshipKeyPathsForPrefetching = [\.route, \.heartRates, \.pauses, \.serviceMappings]
            descriptor.fetchLimit = 1
            let context = ModelContext(self)
            guard let workout = try context.fetch(descriptor).first else { return .failure(WorkoutNotFoundError()) }
            return .success((RawWorkout(workout: workout), workout.persistentModelID))
        } catch {
            return .failure(error)
        }
    }
}

private extension Notification {

    func containsChanges(to persistentModelID: PersistentIdentifier) -> Bool {
        let keys: [ModelContext.NotificationKey] = [.insertedIdentifiers, .updatedIdentifiers, .deletedIdentifiers]
        return keys.contains { key in
            (userInfo?[key.rawValue] as? [PersistentIdentifier])?.contains(persistentModelID) == true
        }
    }
}
