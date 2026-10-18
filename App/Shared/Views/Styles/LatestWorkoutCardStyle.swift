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

struct LatestWorkoutCardStyle: WorkoutCardStyle {

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
                    StaticWorkoutMap(identifier: workout.id)
                } else {
                    StaticWorkoutMap(workout: workout)
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
