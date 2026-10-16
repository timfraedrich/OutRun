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
