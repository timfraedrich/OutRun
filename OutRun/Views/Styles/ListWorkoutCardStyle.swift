import CoreLocation
import OutRunCore
import SwiftUI

struct ListWorkoutCardStyle: WorkoutCardStyle {
    
    @State private var mapWidth: CGFloat?
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: .small) {
            VStack(alignment: .leading, spacing: .small) {
                header(for: configuration.workout)
                metrics(for: configuration.workout)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.small)
            
            optionalMap(for: configuration.workout)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.small)
        .background()
        .overlay { optionalIsRaceBorder(for: configuration.workout) }
        .clipShape(.containerRelative)
        .containerShape(.rect(cornerRadius: .regular))
        .geometryBackground { mapWidth = $0.size.width * 0.45 }
        .backgroundStyle(.secondaryBackground)
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
                    AsyncStaticWorkoutMap(workout: workout, accentColor: .accent)
                } else {
                    StaticWorkoutMap(workout: workout, accentColor: .accent)
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
