import TFRouting

struct SettingsRoutingScope: RoutingScope {
    
    func decide(_ route: any RouteProtocol, in node: RouterNodeSnapshot) -> RoutingDecision {
        switch route {
        case is SettingsPageRoute: .present(.push)
        default: .pass
        }
    }
}
