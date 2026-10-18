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

struct DonationPromptCard: View {
    
    let action: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .regular) {
            header
            button
        }
        .padding(.regular)
        .background()
        .clipShape(.rect(cornerRadius: .regular))
    }

    @ViewBuilder private var header: some View {
        VStack(alignment: .leading, spacing: .small) {
            HStack(spacing: .small) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.tint)
                Text("donation_prompt_title")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("dismiss", systemImage: "xmark", action: dismiss)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }
            .font(.headline)
            Text("donation_prompt_message")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
        }
    }

    @ViewBuilder private var button: some View {
        Button(action: action) {
            Text("donation_prompt_action")
                .bold()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    DonationPromptCard(
        action: {},
        dismiss: {}
    )
    .padding(.regular)
    .backgroundStyle(Color(.secondarySystemGroupedBackground))
    .background(Color(.systemGroupedBackground))
}
