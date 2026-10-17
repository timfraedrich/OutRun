import SwiftUI

struct ChartSelectionBubble: View {
    
    let time: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(verbatim: time)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(verbatim: value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .monospacedDigit()
        .lineLimit(1)
        .padding(.horizontal, .small)
        .padding(.vertical, .extraSmall)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: .small))
        .shadow(color: .black.opacity(0.15), radius: 4, y: 1)
    }
}
