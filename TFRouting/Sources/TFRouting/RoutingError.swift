import Foundation

public enum RoutingError: Error, Hashable, Sendable {
    
    /// No context along the routing tree claimed the route.
    case noHandler(routeType: String)
    /// The context responsible for the route is already presenting another one.
    case presentationBusy
}
