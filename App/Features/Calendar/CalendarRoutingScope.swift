import TFRouting

struct CalendarRoutingScope: RoutingScope {
    
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        switch route {
        case is WorkoutSelectionRoute,
            is WorkoutDetailRoute,
            is WorkoutEditRoute,
            is WorkoutMapRoute:
                .present(.push)
        default: .pass
        }
    }
}
