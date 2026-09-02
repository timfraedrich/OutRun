import SwiftUI

public struct RouteLink<Label: View>: View {
    
    @Environment(RouterNode.self) private var router
    
    let route: any RouteProtocol
    let label: () -> Label
    
    /// - note: The `NavigationLink` to nowhere is what gives the row a list chevron and its navigation
    /// styling, while the enclosing `Button` is what actually runs the routing action.
    public var body: some View {
        Button {
            router.route(route)
        } label: {
            NavigationLink(destination: EmptyView.init, label: label)
        }
    }
    
    public init(route: any RouteProtocol, @ViewBuilder label: @escaping () -> Label) {
        self.route = route
        self.label = label
    }
    
    public init(_ titleKey: LocalizedStringKey, route: any RouteProtocol) where Label == Text {
        self.init(route: route) {
            Text(titleKey)
        }
    }
}

public extension NavigationLink where Destination == Never {
    
    /// - warning: This appends to the enclosing navigation stack directly and bypasses
    /// ``RoutingScope/decide(_:in:)``, so it is limited to navigation that is always a push within a
    /// single feature.
    init(route: any RouteProtocol, @ViewBuilder label: () -> Label) {
        self.init(value: AnyRoute(route), label: label)
    }
}
