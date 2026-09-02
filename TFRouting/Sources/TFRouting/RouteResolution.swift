public enum RouteResolution: Hashable, Sendable {
    
    case resolved(RoutePresentation)
    case failed(RoutingError)
    
    public var isResolved: Bool {
        switch self {
        case .resolved: true
        case .failed: false
        }
    }
}
