public protocol RoutingScope: Sendable {
    
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision
}
