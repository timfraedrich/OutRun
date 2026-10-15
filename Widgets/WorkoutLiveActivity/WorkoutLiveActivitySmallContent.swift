import OutRunCore
import SwiftUI
import WidgetKit

struct WorkoutLiveActivitySmallContent: View {

    @ScaledMetric(relativeTo: .headline) private var iconHeight: CGFloat = 20
    @ScaledMetric private var margin: CGFloat = 8

    let context: ActivityViewContext<WorkoutAttributes>

    var body: some View {
        VStack {
            HStack {
                Image(.oLogo)
                    .resizable()
                    .scaledToFit()
                    .frame(height: iconHeight)
                Spacer()
                Text(context.state.type.description)
            }
            .font(.headline)
            .foregroundStyle(.tint)
            HStack {
                WorkoutLiveActivityDistanceText(context: context)
                WorkoutLiveActivityTimer(context: context)
                    .multilineTextAlignment(.trailing)
            }
        }
        .monospacedDigit()
        .padding(margin)
        .frame(maxWidth: .infinity)
        .tint(.accent)
    }
}
