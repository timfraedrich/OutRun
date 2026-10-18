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
