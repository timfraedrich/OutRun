import SwiftUI

extension View {
    
    @ViewBuilder
    func compatibleSafeAreaBar<Content: View>(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: Spacing,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        compatibleSafeAreaBar(edge: edge, alignment: alignment, spacing: spacing.rawValue, content: content)
    }
    
    @ViewBuilder
    func padding(_ length: Spacing) -> some View {
        self.padding(length.rawValue)
    }
    
    @ViewBuilder
    func padding(_ edges: Edge.Set = .all, _ length: Spacing) -> some View {
        self.padding(edges, length.rawValue)
    }
}
