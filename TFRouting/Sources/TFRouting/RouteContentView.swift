import SwiftUI

public struct RouteContentView: View {
    
    let route: any RouteProtocol
    let context: RouteContext
    
    public var body: some View {
        Self.build(route, in: context)
    }
    
    public init(route: any RouteProtocol, context: RouteContext) {
        self.route = route
        self.context = context
    }
    
    /// - warning: Do not turn this back into a switch over concrete routes. The erasure is confined to
    /// screen roots, one per presentation and one per push, and never occurs within a `ForEach` or list.
    private static func build<R: RouteProtocol>(_ route: R, in context: RouteContext) -> AnyView {
        AnyView(route.content(in: context))
    }
}
