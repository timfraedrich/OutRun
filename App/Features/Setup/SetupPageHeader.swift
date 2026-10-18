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

struct SetupPageHeader<Symbol: View>: View {

    private let symbol: () -> Symbol
    private let titleKey: LocalizedStringKey
    private let messageKey: LocalizedStringKey?

    init(
        title titleKey: LocalizedStringKey,
        message messageKey: LocalizedStringKey? = nil,
        @ViewBuilder symbol: @escaping () -> Symbol
    ) {
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.symbol = symbol
    }

    init(
        systemImage: String,
        title titleKey: LocalizedStringKey,
        message messageKey: LocalizedStringKey? = nil,
    ) where Symbol == SetupPageSymbol {
        self.init(
            title: titleKey,
            message: messageKey,
            symbol: { SetupPageSymbol(systemImage) }
        )
    }

    var body: some View {
        VStack(spacing: .regular) {
            symbol()
            Text(titleKey)
                .font(.largeTitle.bold())
                .fixedSize(horizontal: false, vertical: true)
            if let messageKey {
                Text(messageKey)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
