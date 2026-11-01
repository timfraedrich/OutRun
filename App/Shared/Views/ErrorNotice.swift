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

struct ErrorNotice: View {

    private let error: Error

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 80

    init(_ error: Error) {
        self.error = error
    }

    var body: some View {
        VStack(spacing: .regular) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(height: iconSize)
                .foregroundStyle(.tint)
            Text("error")
                .font(.title.weight(.bold))
            Text(error.localizedDescription)
        }
        .frame(maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .padding(.horizontal, .extraLarge)
        .tint(.red)
    }
}
