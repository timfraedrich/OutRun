import CoreLocation
import OutRunCore
import SwiftUI

struct LatestWorkoutCardStyle: WorkoutCardStyle {
    
    @State private var width: CGFloat?
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: .small) {
            VStack(alignment: .leading, spacing: .small) {
                header(for: configuration.workout)
                metrics(for: configuration.workout)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.small)
            
            optionalMap(for: configuration.workout)
        }
        .padding(.small)
        .background()
        .overlay { optionalIsRaceBorder(for: configuration.workout) }
        .clipShape(.containerRelative)
        .containerShape(.rect(cornerRadius: .regular))
    }
    
    @ViewBuilder
    private func header(for workout: any WorkoutProtocol) -> some View {
        WorkoutHeaderLabeledContent(workout: workout).labeledContentStyle(.metric)
    }
    
    @ViewBuilder
    private func metrics(for workout: any WorkoutProtocol) -> some View {
        AxisGeometryReader(axis: .horizontal, alignment: .leading) { size in
            HFlowLayout(horizontalSpacing: .regular, verticalSpacing: .small) {
                WorkoutMetricLabeledContent(.type, for: workout)
                WorkoutMetricLabeledContent(.distance, for: workout)
                WorkoutMetricLabeledContent(.activeDuration, for: workout)
                WorkoutMetricLabeledContent(.pace, for: workout)
                WorkoutMetricLabeledContent(.energy, for: workout)
            }
            .labeledContentStyle(.metric(size: .small))
            .frame(width: size * 0.7, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private func optionalMap(for workout: any WorkoutProtocol) -> some View {
        if !workout.route.isEmpty {
            Color.clear.overlay(alignment: .center) {
                if workout is Workout {
                    StaticWorkoutMap(identifier: workout.id, accentColor: .accent)
                } else {
                    StaticWorkoutMap(workout: workout, accentColor: .accent)
                }
            }
            .frame(height: 128)
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

extension WorkoutCardStyle where Self == LatestWorkoutCardStyle {
    static var latest: Self { .init() }
}

#Preview {
    VStack {
        WorkoutCard(workout: PreviewConstants.cyclingWorkout)
        WorkoutCard(workout: PreviewConstants.runningWorkout)
    }
    .workoutCardStyle(.latest)
    .padding()
}
