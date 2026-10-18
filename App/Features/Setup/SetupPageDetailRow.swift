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

struct SetupPageDetailRow: View {
    
    @ScaledMetric(relativeTo: .largeTitle) private var symbolWidth: CGFloat = 40
    private let systemImage: String
    private let titleKey: LocalizedStringKey
    private let messageKey: LocalizedStringKey?
    
    var body: some View {
        HStack(alignment: .center, spacing: .large) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: symbolWidth)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text(titleKey)
                    .font(.headline)
                if let messageKey {
                    Text(messageKey)
                        .font(.footnote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .multilineTextAlignment(.leading)
        .listRowInsets(.init(top: Spacing.regular.rawValue, leading: 0, bottom: Spacing.regular.rawValue, trailing: 0))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    init(_ titleKey: LocalizedStringKey, message messageKey: LocalizedStringKey? = nil, systemImage: String) {
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.systemImage = systemImage
    }
}
