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

struct CalendarLegend: View {

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: .regular) {
                items
            }
            HFlowLayout(horizontalSpacing: .small, verticalSpacing: .small, alignment: .center) {
                items
            }
        }
        .font(.caption)
        .fontWeight(.medium)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder private var items: some View {
        ForEach(WorkoutType.allCases, id: \.rawValue) { type in
            HStack(spacing: .extraSmall) {
                Circle()
                    .foregroundStyle(type.color)
                    .frame(width: 6, height: 6)
                Text(type.description)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    CalendarLegend()
}
