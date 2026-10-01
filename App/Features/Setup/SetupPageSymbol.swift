import SwiftUI

struct SetupPageSymbol: View {

    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 100
    private let image: Image

    init(_ systemImage: String) {
        self.image = Image(systemName: systemImage)
    }

    init(_ image: Image) {
        self.image = image
    }

    var body: some View {
        image
            .font(.system(size: size))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(.tint)
    }
}
