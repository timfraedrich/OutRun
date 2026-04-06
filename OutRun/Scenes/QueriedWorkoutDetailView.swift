import OutRunCore
import SwiftData
import SwiftUI

struct QueriedWorkoutDetailView: View {
    
    @Query private var workouts: [Workout]
    
    var body: some View {
        if let workout = workouts.first {
            WorkoutDetailView(workout: workout)
        }
    }
    
    init(id: Workout.ID) {
        _workouts = Query(.init(predicate: #Predicate { $0.id == id }))
    }
}
