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

struct SavedWorkoutNotice: View {

    let open: () -> Void
    let delete: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            header
            buttons
        }
        .padding(.regular)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { MapOverlayBackground(shape: .rect(cornerRadius: .large)) }
    }

    @ViewBuilder private var header: some View {
        HStack(spacing: .small) {
            Group {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
                Text("recording_saved_workout")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.title3.weight(.bold))
            Button("close", systemImage: "xmark", action: dismiss)
                .buttonStyle(.plain)
                .labelStyle(.iconOnly)
        }
    }

    @ViewBuilder private var buttons: some View {
        HStack(spacing: .regular) {
            Button(role: .destructive, action: delete) {
                Text("delete")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.actionProminent)
            .tint(.red.opacity(0.8))

            Button(action: open) {
                Text("open")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.action)
        }
        .font(.subheadline.weight(.semibold))

    }
}
