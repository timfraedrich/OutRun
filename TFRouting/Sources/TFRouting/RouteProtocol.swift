import SwiftUI

/// A screen that can be navigated to, declared by the feature owning it.
/// - note: Routes are deliberately not `Identifiable`; identity is derived from the route value itself by ``AnyRoute``.
public protocol RouteProtocol: Hashable, Sendable {
    
    associatedtype Content: View
    
    var defaultPresentation: RoutePresentation { get }
    
    @MainActor @ViewBuilder func content(in context: RouteContext) -> Content
    
    func scope() -> (any RoutingScope)?
}

public extension RouteProtocol {
    
    var defaultPresentation: RoutePresentation { .push }
    
    func scope() -> (any RoutingScope)? { nil }
}
