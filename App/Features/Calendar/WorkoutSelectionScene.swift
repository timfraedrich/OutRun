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
