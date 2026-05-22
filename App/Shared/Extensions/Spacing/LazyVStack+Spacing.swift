import SwiftUI

extension LazyVStack {
    
    init(
        alignment: HorizontalAlignment = .center,
        spacing: Spacing,
        pinnedViews: PinnedScrollableViews = .init(),
        @ViewBuilder content: () -> Content
    ) {
        self.init(alignment: alignment, spacing: spacing.rawValue, pinnedViews: pinnedViews, content: content)
    }
}
