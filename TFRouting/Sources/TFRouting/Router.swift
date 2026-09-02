import SwiftUI

/// The root of the routing tree.
///
/// - note: ``root`` exists from launch on, so routes resolve against the model whether or not any view
/// backing them has been created yet; the user interface catches up afterwards.
@Observable
@MainActor
public final class Router {
    
    public let root: RouterNode
    public var lastFailure: RoutingError?
    
    public init(scope: any RoutingScope = DefaultScope()) {
        root = RouterNode(scope: scope)
    }
    
    @discardableResult
    public func route(_ route: any RouteProtocol) -> RouteResolution {
        record(root.route(route))
    }
    
    @discardableResult
    public func open(_ program: [any RouteProtocol]) -> RouteResolution {
        record(root.open(program))
    }
    
    @discardableResult
    public func open(_ route: any RouteProtocol) -> RouteResolution {
        open([route])
    }
    
    private func record(_ resolution: RouteResolution) -> RouteResolution {
        if case .failed(let error) = resolution {
            lastFailure = error
        }
        return resolution
    }
}
