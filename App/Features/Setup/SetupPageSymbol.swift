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

struct SetupPageSymbol: View {

    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 100
    private let image: Image

    init(_ systemImage: String) {
        self.image = Image(systemName: systemImage)
    }

    init(_ image: Image) {
        self.image = image
    }

    var body: some View {
        image
            .font(.system(size: size))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.tint)
    }
}
