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
        Group {
            if let name = workout.name {
                LabeledContent {
                    Text(name)
                } label: {
                    HStack(spacing: .small) {
                        WorkoutMetricText(metricValue: .type(workout.type))
                        RelativeDayDateText(workout.startDate)
                    }
                }
            } else {
                LabeledContent {
                    RelativeDayDateText(workout.startDate)
                } label: {
                    WorkoutMetricText(metricValue: .type(workout.type))
                }
            }
        }
        .labeledContentStyle(.metric)
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
                StaticWorkoutMap(workout: workout, accentColor: .accent)
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
        WorkoutCard(workout: RawWorkout(
            id: .init(),
            type: .cycling,
            distance: 7892,
            startDate: .now,
            endDate: .now.addingTimeInterval(1201),
            energy: 2300 * 1000,
            repetitions: nil,
            isRace: true,
            name: nil,
            comment: nil,
            creationDate: .now,
            lastEditDate: .now,
            sourceService: .native
        ))
        WorkoutCard(workout: RawWorkout(
            id: .init(),
            type: .running,
            distance: 1300,
            startDate: .now.addingTimeInterval(-900000),
            endDate: .now.addingTimeInterval(-900000 + 901),
            energy: 900 * 1000,
            repetitions: nil,
            isRace: false,
            name: "Morning Run",
            comment: nil,
            creationDate: .now,
            lastEditDate: .now,
            sourceService: .native,
            route: PreviewConstants.route
        ))
    }
    .workoutCardStyle(.list)
    .padding()
}
