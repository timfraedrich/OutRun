import OutRunCore
import SwiftData
import SwiftUI

struct QueriedWorkoutDetailScene: View {
    
    @Query private var workouts: [Workout]
    let addCloseButton: Bool
    
    var body: some View {
        if let workout = workouts.first {
            WorkoutDetailScene(workout: workout, addCloseButton: addCloseButton)
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
        }
    }
    
    init(id: Workout.ID, addCloseButton: Bool) {
        var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id })
        descriptor.relationshipKeyPathsForPrefetching = [\.route, \.heartRates, \.pauses, \.serviceMappings]
        descriptor.fetchLimit = 1
        _workouts = Query(descriptor)
        self.addCloseButton = addCloseButton
    }
}
