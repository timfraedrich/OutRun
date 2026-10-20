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

struct SetupPageView<Symbol: View, Content: View>: View {

    private let symbol: () -> Symbol
    private let titleKey: LocalizedStringKey
    private let messageKey: LocalizedStringKey?
    private let content: () -> Content

    var body: some View {
        List {
            header
            content()
        }
        .contentMargins(.extraLarge, for: .scrollContent)
        .scrollDismissesKeyboard(.interactively)
    }
    
    @ViewBuilder private var header: some View {
        Section {
            SetupPageHeader(title: titleKey, message: messageKey, symbol: symbol)
                .padding(.vertical, .extraLarge)
                .listRowInsets(.init())
                .listRowBackground(Color.clear)
        }
    }
    
    init(
        title titleKey: LocalizedStringKey,
        message messageKey: LocalizedStringKey? = nil,
        @ViewBuilder symbol: @escaping () -> Symbol,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.symbol = symbol
        self.content = content
    }

    init(
        title titleKey: LocalizedStringKey,
        message messageKey: LocalizedStringKey? = nil,
        @ViewBuilder symbol: @escaping () -> Symbol
    ) where Content == EmptyView {
        self.init(
            title: titleKey,
            message: messageKey,
            symbol: symbol,
            content: EmptyView.init
        )
    }

    init(
        systemImage: String,
        title titleKey: LocalizedStringKey,
        message messageKey: LocalizedStringKey? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where Symbol == SetupPageSymbol {
        self.init(
            title: titleKey,
            message: messageKey,
            symbol: { SetupPageSymbol(systemImage) },
            content: content
        )
    }
    
    init(
        systemImage: String,
        title titleKey: LocalizedStringKey,
        message messageKey: LocalizedStringKey? = nil,
    ) where Symbol == SetupPageSymbol, Content == EmptyView {
        self.init(
            systemImage: systemImage,
            title: titleKey,
            message: messageKey,
            content: EmptyView.init
        )
    }
}

#Preview {
    SetupPageView(
        systemImage: "globe",
        title: "Example Title",
        message: "This is an example setup page",
    ) {
        Text("This is some content.")
    }
    .background(Color(.systemGroupedBackground))
    .customBottomSafeAreaBar {
        ActionButton("Action", action: {})
    }
}

#Preview {
    SetupPageView(systemImage: "checkmark.circle.fill", title: "Example Title", message: "This is an example setup page")
        .background(Color(.systemGroupedBackground))
        .customBottomSafeAreaBar {
            ActionButton("Action", action: {})
        }
}

#Preview {
    SetupPageView(
        title: "Example Title",
        message: "This is an example setup page",
    ) {
        Image(.oLogo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 100)
    } content: {
        ForEach(0..<12) { _ in
            Text("This is some content.")
        }
    }
    .background(Color(.systemGroupedBackground))
    .customBottomSafeAreaBar {
        VStack(spacing: .small) {
            ActionButton("Secondary Action", prominent: false, action: {})
            ActionButton("Action", action: {})
        }
    }
}
