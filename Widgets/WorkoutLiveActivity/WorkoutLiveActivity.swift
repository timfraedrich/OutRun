//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
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

import ActivityKit
import OutRunCore
import SwiftUI
import WidgetKit

struct WorkoutLiveActivity: Widget {

    @ScaledMetric(relativeTo: .footnote) private var iconHeight: CGFloat = 15

    @ViewBuilder private var dynamicIslandIcon: some View {
        WorkoutLiveActivityIcon()
            .padding(2)
            .foregroundStyle(.tint)
            .tint(.accent)
    }

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutAttributes.self, content: WorkoutLiveActivityContent.init) { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        WorkoutLiveActivityIcon()
                            .frame(height: iconHeight)
                        Text(context.state.type.description)
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                    }
                    .font(.footnote.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .foregroundStyle(.tint)
                    .tint(.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    WorkoutLiveActivityTimer(context: context)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .minimumScaleFactor(0.1)
                        .monospacedDigit()
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    WorkoutLiveActivityDistanceText(context: context)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.largeTitle.weight(.bold))
                        .monospacedDigit()
                        .userPreferences(of: context)
                        .padding([.horizontal, .bottom], 8)
                }
            } compactLeading: {
                dynamicIslandIcon
            } compactTrailing: {
                Image(systemName: context.state.isPaused ? "pause.fill" : "record.circle")
                    .resizable()
                    .scaledToFit()
                    .padding(context.state.isPaused ? 4 : 2)
                    .foregroundStyle(.tint)
                    .tint(.accent)
            } minimal: {
                dynamicIslandIcon
            }
            .keylineTint(.accent)
        }
        .supplementalActivityFamilies([.small])
    }
}

extension WorkoutAttributes {
    fileprivate static var preview: WorkoutAttributes {
        WorkoutAttributes()
    }
}

extension WorkoutAttributes.ContentState {
    fileprivate static var recording: WorkoutAttributes.ContentState {
        WorkoutAttributes.ContentState(
            type: .running,
            isPaused: false,
            duration: .increasing(since: .now, offset: -200),
            distance: .init(value: 2_543, unit: .meters),
            preferences: [:]
        )
    }

    fileprivate static var paused: WorkoutAttributes.ContentState {
        WorkoutAttributes.ContentState(
            type: .cycling,
            isPaused: true,
            duration: .constant(1_237),
            distance: .init(value: 12_540, unit: .meters),
            preferences: [:]
        )
    }
}

#Preview("Notification", as: .content, using: WorkoutAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState.recording
    WorkoutAttributes.ContentState.paused
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: WorkoutAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState.recording
    WorkoutAttributes.ContentState.paused
}

#Preview("Compact", as: .dynamicIsland(.compact), using: WorkoutAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState.recording
    WorkoutAttributes.ContentState.paused
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: WorkoutAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutAttributes.ContentState.recording
}
