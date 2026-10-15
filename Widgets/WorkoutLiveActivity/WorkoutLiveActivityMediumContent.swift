import OutRunCore
import SwiftUI
import WidgetKit

struct WorkoutLiveActivityMediumContent: View {

    @ScaledMetric(relativeTo: .headline) private var iconHeight: CGFloat = 20
    @ScaledMetric(relativeTo: .title) private var spacing: CGFloat = 8

    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: spacing) {
                Group {
                    WorkoutLiveActivityIcon()
                        .frame(height: iconHeight)
                    Text(context.state.type.description)
                }
                .foregroundStyle(.tint)
                Spacer()
                WorkoutLiveActivityTimer(context: context)
                    .multilineTextAlignment(.trailing)
            }
            .font(.headline)
            WorkoutLiveActivityDistanceText(context: context)
                .font(.title.weight(.bold))
        }
        .monospacedDigit()
        .padding(spacing * 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.opacity(0.5))
        .activityBackgroundTint(.accent.opacity(0.2))
        .tint(.accent)
    }
}
