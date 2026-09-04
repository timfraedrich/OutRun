import OutRunCore
import SwiftData
import SwiftUI

struct QueriedWorkoutEditScene: View {
    
    let id: Workout.ID
    let addCloseButton: Bool
    
    var body: some View {
        QueriedWorkoutWrapper(id: id) { workout in
            WorkoutEditScene(workout: workout, addCloseButton: addCloseButton)
        }
    }
    
    init(id: Workout.ID, addCloseButton: Bool = true) {
        self.id = id
        self.addCloseButton = addCloseButton
    }
}
