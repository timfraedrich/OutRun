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
