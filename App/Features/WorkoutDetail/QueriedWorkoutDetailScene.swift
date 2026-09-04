import OutRunCore
import SwiftData
import SwiftUI

struct QueriedWorkoutDetailScene: View {
    
    private let id: Workout.ID
    private let addCloseButton: Bool
    
    var body: some View {
        QueriedWorkoutWrapper(id: id) { workout in
            WorkoutDetailScene(workout: workout, addCloseButton: addCloseButton)
        }
    }
    
    init(id: Workout.ID, addCloseButton: Bool) {
        self.id = id
        self.addCloseButton = addCloseButton
    }
}
