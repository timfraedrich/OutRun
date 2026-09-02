public struct DefaultScope: RoutingScope {
    
    public func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        route.defaultPresentation == .push ? .present(.push) : .pass
    }
    
    public init() {}
}
