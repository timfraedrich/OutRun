import SwiftUI

extension LazyVGrid {
    
    init(
        columns: [GridItem],
        alignment: HorizontalAlignment = .center,
        spacing: Spacing,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) {
        self.init(columns: columns, alignment: alignment, spacing: spacing.rawValue, pinnedViews: pinnedViews, content: content)
    }
}
