import SwiftUI

public struct RouterHost<Content: View>: View {
    
    @Bindable var node: RouterNode
    @ViewBuilder let content: () -> Content
    
    public var body: some View {
        NavigationStack(path: $node.path) {
            content()
                .navigationDestination(for: AnyRoute.self) { route in
                    RouteContentView(route: route.base, context: .init(presentation: .push))
                }
        }
        .environment(node)
        .sheet(item: modal { $0.isSheet }) { presented in
            modalBody(presented)
        }
        .fullScreenCover(item: modal { $0 == .fullScreenCover }) { presented in
            modalBody(presented)
        }
    }
    
    public init(node: RouterNode, @ViewBuilder content: @escaping () -> Content) {
        self.node = node
        self.content = content
    }
    
    /// Hosting the presented node rather than this one is what makes `@Environment(RouterNode.self)`
    /// inside a modal resolve to the modal's own context instead of the presenting one.
    ///
    /// - note: The recursion is what allows sheets above sheets, as SwiftUI honours only a single
    /// `.sheet(item:)` per view.
    @ViewBuilder
    private func modalBody(_ presented: RouterNode.Presented) -> some View {
        // Pinning the generic parameter terminates the otherwise infinite recursive type expansion.
        RouterHost<RouteContentView>(node: presented.child) {
            RouteContentView(
                route: presented.route.base,
                context: .init(presentation: presented.presentation)
            )
        }
        .id(presented.route.id)
    }
    
    private func modal(kind: @escaping (RoutePresentation) -> Bool) -> Binding<RouterNode.Presented?> {
        .init(
            get: { node.modal.flatMap { kind($0.presentation) ? $0 : nil } },
            set: { if $0 == nil, let current = node.modal, kind(current.presentation) { node.modal = nil } }
        )
    }
}
