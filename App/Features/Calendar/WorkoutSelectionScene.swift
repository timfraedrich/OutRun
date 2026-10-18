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
import TFRouting

struct WorkoutSelectionScene: View {
    
    @Environment(RouterNode.self) var node
    @Query private var workouts: [Workout]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .small) {
                ForEach(workouts) { workout in
                    Button {
                        node.route(WorkoutDetailRoute(id: workout.id))
                    } label: {
                        WorkoutCard(workout: workout)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .regular)
            .padding(.vertical, .regular)
            .backgroundStyle(Color(.secondarySystemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("workouts")
        .navigationBarTitleDisplayMode(.large)
    }

    init(between startDate: Date, and endDate: Date) {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate { $0.startDate >= startDate && $0.startDate < endDate },
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        descriptor.propertiesToFetch = [\.rawType, \.startDate, \.endDate, \.distance, \.energy]
        descriptor.relationshipKeyPathsForPrefetching = [\.pauses]
        _workouts = .init(descriptor)
    }
}
