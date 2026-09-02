import TFRouting

struct MainRoutingScope: RoutingScope {
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        switch route {
        case is CalendarRoute,
            is WorkoutDetailRoute,
            is WorkoutEditRoute,
            is WorkoutMapRoute,
            is SettingsRoute:
                .present(.sheet)
        case is RecordingRoute:
                .present(.fullScreenCover)
        default:
                .pass
        }
    }
}
