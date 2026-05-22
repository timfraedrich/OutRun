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
        padding(length.rawValue)
    }
    
    @ViewBuilder
    func padding(_ edges: Edge.Set, _ length: Spacing) -> some View {
        padding(edges, length.rawValue)
    }
    
    @ViewBuilder
    func safeAreaPadding(_ length: Spacing) -> some View {
        safeAreaPadding(length.rawValue)
    }
    
    @ViewBuilder
    func safeAreaPadding(_ edges: Edge.Set, _ length: Spacing) -> some View {
        safeAreaPadding(edges, length.rawValue)
    }
}
