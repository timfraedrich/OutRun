public enum RoutingDecision: Hashable, Sendable {
    
    case present(RoutePresentation)
    /// The parent context is asked next.
    case pass
    /// Does not bubble up.
    case reject(RoutingError)
}
