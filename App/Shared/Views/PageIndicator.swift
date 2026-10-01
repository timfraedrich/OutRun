import SwiftUI

struct PageIndicator<Item: Hashable>: View {

    let items: [Item]
    let selection: Item?

    @ScaledMetric private var size: CGFloat = 7

    var body: some View {
        HStack(spacing: .small) {
            ForEach(items, id: \.self) { item in
                Circle()
                    .frame(width: size, height: size)
                    .foregroundStyle(selection == item ? .primary : .secondary)
            }
        }
    }
}
