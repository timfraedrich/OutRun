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
