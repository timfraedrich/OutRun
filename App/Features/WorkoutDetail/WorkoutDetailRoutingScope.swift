import TFRouting

struct WorkoutDetailRoutingScope: RoutingScope {
    
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        switch route {
        case is WorkoutEditRoute, is WorkoutMapRoute: .present(.push)
        default: .pass
        }
    }
}
