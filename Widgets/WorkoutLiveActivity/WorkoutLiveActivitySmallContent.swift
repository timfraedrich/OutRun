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
