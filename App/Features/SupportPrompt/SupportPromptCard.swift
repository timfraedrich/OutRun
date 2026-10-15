import SwiftUI

struct SupportPromptCard: View {
    
    let title: Text
    let message: Text
    let systemImage: String
    let actionTitle: Text
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
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
                title
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("dismiss", systemImage: "xmark", action: dismiss)
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }
            .font(.headline)
            message
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
        }
    }

    @ViewBuilder private var button: some View {
        Button(action: action) {
            actionTitle
                .bold()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    SupportPromptCard(
        title: Text(verbatim: "Enjoying OutRun?"),
        message: Text(verbatim: "Leaving a review is a great way to support the app."),
        systemImage: "star.fill",
        actionTitle: Text(verbatim: "Rate now"),
        action: {},
        dismiss: {}
    )
    .padding(.regular)
    .backgroundStyle(Color(.secondarySystemGroupedBackground))
    .background(Color(.systemGroupedBackground))
}
