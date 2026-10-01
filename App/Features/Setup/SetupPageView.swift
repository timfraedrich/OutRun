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
