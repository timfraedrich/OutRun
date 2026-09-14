import CoreLocation
import OutRunCore
import SwiftUI

private struct ListWorkoutCardStyleView: View {

    let workout: any WorkoutProtocol

    @State private var mapWidth: CGFloat?

    var body: some View {
        HStack(alignment: .top, spacing: .small) {
            VStack(alignment: .leading, spacing: .small) {
                header(for: workout)
                metrics(for: workout)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.small)

            optionalMap(for: workout)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.small)
        .background()
        .overlay { optionalIsRaceBorder(for: workout) }
        .clipShape(.containerRelative)
        .containerShape(.rect(cornerRadius: .regular))
        .geometryBackground { mapWidth = $0.size.width * 0.45 }
    }

    @ViewBuilder
    private func header(for workout: any WorkoutProtocol) -> some View {
        WorkoutHeaderLabeledContent(workout: workout).labeledContentStyle(.metric)
    }

    @ViewBuilder
    private func metrics(for workout: any WorkoutProtocol) -> some View {
        HFlowLayout(horizontalSpacing: Spacing.regular, verticalSpacing: .small) {
            WorkoutMetricLabeledContent(.distance, for: workout)
            WorkoutMetricLabeledContent(.activeDuration, for: workout)
            WorkoutMetricLabeledContent(.pace, for: workout)
        }
        .labeledContentStyle(.metric(size: .small))
    }

    @ViewBuilder
    private func optionalMap(for workout: any WorkoutProtocol) -> some View {
        if !workout.route.isEmpty {
            Color.clear.overlay(alignment: .center) {
                if workout is Workout {
                    StaticWorkoutMap(identifier: workout.id)
                } else {
                    StaticWorkoutMap(workout: workout)
                }
            }
            .frame(width: mapWidth)
            .clipShape(.containerRelative)
        }
    }

    @ViewBuilder
    private func optionalIsRaceBorder(for workout: any WorkoutProtocol) -> some View {
        if workout.isRace {
            ContainerRelativeShape()
                .strokeBorder(lineWidth: 4)
                .foregroundStyle(.tint.opacity(0.5))
        }
    }
}

struct ListWorkoutCardStyle: WorkoutCardStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        ListWorkoutCardStyleView(workout: configuration.workout)
    }
}

extension WorkoutCardStyle where Self == ListWorkoutCardStyle {
    static var list: Self { .init() }
}

#Preview {
    VStack {
        WorkoutCard(workout: PreviewConstants.cyclingWorkout)
        WorkoutCard(workout: PreviewConstants.runningWorkout)
    }
    .workoutCardStyle(.list)
    .padding()
}
