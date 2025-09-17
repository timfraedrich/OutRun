import SwiftUI

struct HFlowLayout: Layout {
    
    /// Horizontal spacing between items in the same row
    private let horizontalSpacing: CGFloat
    /// Vertical spacing between rows
    private let verticalSpacing: CGFloat
    /// Alignment of items within each row
    private let alignment: HorizontalAlignment
    
    init(
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        alignment: HorizontalAlignment = .leading
    ) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.alignment = alignment
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        let availableWidth = proposal.width ?? .infinity
        let rows = calculateLayout(subviews: subviews, availableWidth: availableWidth, cache: &cache)
        let totalHeight = rows.reduce(CGFloat.zero) { result, row in
            result + row.height + (row == rows.last ? 0 : verticalSpacing)
        }
        let maxWidth = rows.map { $0.width }.max() ?? 0
        return CGSize(
            width: min(maxWidth, availableWidth),
            height: totalHeight
        )
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        guard !subviews.isEmpty else { return }
        let availableWidth = bounds.width
        let rows = calculateLayout(subviews: subviews, availableWidth: availableWidth, cache: &cache)
        var currentY = bounds.minY
        var subviewIndex = 0
        for row in rows {
            let rowStartX: CGFloat
            switch alignment {
            case .leading: rowStartX = bounds.minX
            case .center: rowStartX = bounds.minX + (availableWidth - row.width) / 2
            case .trailing: rowStartX = bounds.maxX - row.width
            default: rowStartX = bounds.minX
            }
            var currentX = rowStartX
            for _ in 0..<row.count {
                let subview = subviews[subviewIndex]
                let subviewSize = subview.sizeThatFits(.unspecified)
                let itemY = currentY + (row.height - subviewSize.height) / 2
                subview.place(
                    at: CGPoint(x: currentX, y: itemY),
                    proposal: ProposedViewSize(subviewSize)
                )
                currentX += subviewSize.width + horizontalSpacing
                subviewIndex += 1
            }
            currentY += row.height + verticalSpacing
        }
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    private func calculateLayout(
        subviews: Subviews,
        availableWidth: CGFloat,
        cache: inout Cache
    ) -> [Row] {
        var rows: [Row] = []
        var currentRowItems: [SubviewInfo] = []
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            let subviewInfo = SubviewInfo(size: subviewSize)
            let itemWidth = subviewSize.width
            let requiredWidth = currentRowWidth + (currentRowItems.isEmpty ? 0 : horizontalSpacing) + itemWidth
            if requiredWidth <= availableWidth || currentRowItems.isEmpty {
                if !currentRowItems.isEmpty {
                    currentRowWidth += horizontalSpacing
                }
                currentRowItems.append(subviewInfo)
                currentRowWidth += itemWidth
                currentRowHeight = max(currentRowHeight, subviewSize.height)
            } else {
                if !currentRowItems.isEmpty {
                    rows.append(Row(
                        items: currentRowItems,
                        width: currentRowWidth,
                        height: currentRowHeight,
                        count: currentRowItems.count
                    ))
                }
                currentRowItems = [subviewInfo]
                currentRowWidth = itemWidth
                currentRowHeight = subviewSize.height
            }
        }
        if !currentRowItems.isEmpty {
            rows.append(Row(
                items: currentRowItems,
                width: currentRowWidth,
                height: currentRowHeight,
                count: currentRowItems.count
            ))
        }
        return rows
    }
    
    struct Cache {
        private var rows: [Row] = []
    }
    
    private struct Row: Equatable {
        let items: [SubviewInfo]
        let width: CGFloat
        let height: CGFloat
        let count: Int
    }
    
    private struct SubviewInfo: Equatable {
        let size: CGSize
    }
}

#Preview {
    let elements = ["Lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit"]
    HFlowLayout {
        ForEach(elements, id: \.self) { element in
            Text(element)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(hue: .random(in: 0...1), saturation: 0.5, brightness: 1))
                .clipShape(.capsule)
        }
    }
}
