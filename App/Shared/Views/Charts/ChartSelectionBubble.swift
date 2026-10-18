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

import SwiftUI

struct ChartSelectionBubble: View {
    
    let time: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(verbatim: time)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(verbatim: value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .monospacedDigit()
        .lineLimit(1)
        .padding(.horizontal, .small)
        .padding(.vertical, .extraSmall)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: .small))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
    }
}
