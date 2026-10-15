import OutRunCore
import SwiftUI
import WidgetKit

struct WorkoutLiveActivityDistanceText: View {

    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        WorkoutMetricText(metricValue: .longDistanceMeasurement(context.state.distance))
    }
}
