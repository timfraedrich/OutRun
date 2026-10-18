//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
