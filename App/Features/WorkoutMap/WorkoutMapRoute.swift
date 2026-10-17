import OutRunCore
import SwiftUI
import TFRouting

struct WorkoutMapRoute: RouteProtocol {
    
    let id: Workout.ID
    var metric: WorkoutChartMetric = .speed
    
    func content(in context: RouteContext) -> some View {
        WorkoutMapScene(id: id, metric: metric, addCloseButton: context.isModalRoot)
    }
}
