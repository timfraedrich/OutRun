import OutRunCore
import SwiftUI
import WidgetKit

struct WorkoutLiveActivityContent: View {

    @Environment(\.activityFamily) private var family

    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        switch family {
        case .medium:
            WorkoutLiveActivityMediumContent(context: context)
                .userPreferences(of: context)
        case .small:
            WorkoutLiveActivitySmallContent(context: context)
                .userPreferences(of: context)
        @unknown default:
            EmptyView()
        }
    }
}
