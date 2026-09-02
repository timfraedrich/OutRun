import OutRunCore
import SwiftUI
import TFRouting

struct WorkoutDetailRoute: RouteProtocol {
    
    let id: Workout.ID
    
    func content(in context: RouteContext) -> some View {
        QueriedWorkoutDetailScene(id: id, addCloseButton: context.isModalRoot)
    }
    
    func scope() -> (any RoutingScope)? {
        WorkoutDetailRoutingScope()
    }
}
