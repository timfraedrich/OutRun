import SwiftUI

struct HealthSyncModeOptionView: View {
    
    private let titleKey: LocalizedStringKey
    private let imageName: String
    private let messageKey: LocalizedStringKey
    
    var body: some View {
        VStack(alignment: .leading, spacing: .extraSmall) {
            HStack(spacing: .small) {
                Image(systemName: imageName)
                    .foregroundStyle(.tint)
                Text(titleKey)
            }
            .font(.headline)
            Text(messageKey)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    init(_ titleKey: LocalizedStringKey, imageName: String, messageKey: LocalizedStringKey) {
        self.titleKey = titleKey
        self.imageName = imageName
        self.messageKey = messageKey
    }
}
