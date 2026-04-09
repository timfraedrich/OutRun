import OutRunCore
import SwiftData
import SwiftUI

struct QueriedWorkoutDetailScene: View {
    
    @Query private var workouts: [Workout]
    let addCloseButton: Bool
    
    var body: some View {
        if let workout = workouts.first {
            WorkoutDetailScene(workout: workout, addCloseButton: addCloseButton)
        }
    }
    
    init(id: Workout.ID, addCloseButton: Bool = true) {
        _workouts = Query(.init(predicate: #Predicate { $0.id == id }))
        self.addCloseButton = addCloseButton
    }
}
