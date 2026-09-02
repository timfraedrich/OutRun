import OutRunCore
import SwiftUI
import TFRouting

struct WorkoutMapRoute: RouteProtocol {
    
    let id: Workout.ID
    
    func content(in context: RouteContext) -> some View {
        WorkoutMapScene(id: id)
    }
}
