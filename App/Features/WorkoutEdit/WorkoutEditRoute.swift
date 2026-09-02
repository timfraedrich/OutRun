import OutRunCore
import SwiftUI
import TFRouting

struct WorkoutEditRoute: RouteProtocol {
    
    let id: Workout.ID?
    
    func content(in context: RouteContext) -> some View {
        if let id {
            QueriedWorkoutEditScene(id: id, addCloseButton: context.isModalRoot)
        } else {
            WorkoutEditScene(workout: nil, addCloseButton: context.isModalRoot)
        }
    }
}

