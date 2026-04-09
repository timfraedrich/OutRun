import OutRunCore
import SwiftData
import SwiftUI

struct WorkoutSelectionScene: View {
    
    @Environment(MainRouter.self) private var mainRouter
    @Query private var workouts: [Workout]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .small) {
                ForEach(workouts) { workout in
                    NavigationLink(value: CalendarNavigationDestination.workoutDetails(id: workout.id)) {
                        WorkoutCard(workout: workout)
                    }
                }
            }
            .padding(.horizontal, .regular)
            .padding(.vertical, .regular)
        }
        .background()
        .navigationTitle("Workouts")
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
