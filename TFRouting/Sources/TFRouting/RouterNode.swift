import SwiftUI

/// A single presentation context, consisting of one navigation stack, one modal slot and its branches.
///
/// - note: Presented nodes are owned strongly through ``modal`` while ``parent`` is weak, so clearing
/// the slot deallocates the presented node along with its entire path.
@Observable
@MainActor
public final class RouterNode {
    
    public var path: [AnyRoute] = []
    public var modal: Presented?
    public var selection: AnyRoute?
    
    public let scope: any RoutingScope
    public private(set) weak var parent: RouterNode?
    
    /// - note: Unobserved so that reading and creating a branch in the same body pass does not
    /// re-invalidate that pass.
    @ObservationIgnored private var branches: [AnyRoute: RouterNode] = [:]
    
    /// The presented modals, innermost last.
    public var modalStack: [Presented] {
        var stack: [Presented] = []
        var node = self
        while let child = node.routingChild {
            if let presented = node.modal { stack.append(presented) }
            node = child
        }
        return stack
    }
    
    private var snapshot: RouterNodeSnapshot {
        .init(path: path, isPresentingModally: modal != nil)
    }
    
    /// The innermost context along the routing chain, whose modal slot is the one still free.
    private var deepestNode: RouterNode { routingChild?.deepestNode ?? self }
    
    private var routingChild: RouterNode? {
        modal?.child ?? selection.flatMap { branches[$0] }
    }
    
    public init(scope: any RoutingScope = DefaultScope(), parent: RouterNode? = nil) {
        self.scope = scope
        self.parent = parent
    }
    
    /// Routes relative to this context, preferring the deepest presented one and bubbling up from there.
    @discardableResult
    public func route(_ route: any RouteProtocol) -> RouteResolution {
        if let routingChild {
            let resolution = routingChild.route(route)
            guard case .failed(.noHandler) = resolution else { return resolution }
        }
        return handle(route)
    }
    
    /// Routes absolutely by walking a program of routes down the tree, for deep links.
    ///
    /// - note: This resolves entirely within the model, before any of the involved views exist.
    @discardableResult
    public func open(_ program: [any RouteProtocol]) -> RouteResolution {
        dismissAll()
        popToRoot()
        var cursor = self
        for route in program {
            switch cursor.scope.decide(route, in: cursor.snapshot) {
            case .present(let presentation):
                let resolution = cursor.apply(presentation, to: AnyRoute(route))
                guard resolution.isResolved else { return resolution }
                switch presentation {
                case .push:
                    break
                case .sheet, .fullScreenCover:
                    cursor = cursor.deepestNode
                case .selection:
                    cursor = cursor.branch(for: route)
                }
            case .reject(let error):
                return .failed(error)
            case .pass:
                return .failed(.noHandler(routeType: String(describing: type(of: route))))
            }
        }
        return .resolved(.push)
    }
    
    /// The node backing a parallel context, created on first use and retained afterwards so its
    /// navigation state survives switching away and back.
    public func branch(for route: any RouteProtocol) -> RouterNode {
        let key = AnyRoute(route)
        if let branch = branches[key] { return branch }
        let branch = RouterNode(scope: route.scope() ?? DefaultScope(), parent: self)
        branches[key] = branch
        return branch
    }
    
    public func discardBranch(for route: any RouteProtocol) {
        branches[AnyRoute(route)] = nil
    }
    
    /// Truncates the modal chain at `index`, counted from this context inwards.
    public func dismissModals(from index: Int) {
        var node = self
        var remaining = max(index, 0)
        while let child = node.routingChild {
            if node.modal != nil {
                guard remaining > 0 else { break }
                remaining -= 1
            }
            node = child
        }
        node.modal = nil
    }
    
    public func dismissAll() {
        var node = self
        while let child = node.routingChild {
            node.modal = nil
            node = child
        }
    }
    
    public func popToRoot() {
        path.removeAll()
    }
    
    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    private func handle(_ route: any RouteProtocol) -> RouteResolution {
        switch scope.decide(route, in: snapshot) {
        case .present(let presentation):
            return apply(presentation, to: AnyRoute(route))
        case .reject(let error):
            return .failed(error)
        case .pass:
            break
        }
        guard let parent else { return .failed(.noHandler(routeType: String(describing: type(of: route)))) }
        return parent.handle(route)
    }
    
    /// - note: Modals are applied to ``deepestNode``, whose slot is empty, so a modal slot never swaps
    /// from one route to another; a route already in the chain is rejected rather than presented twice.
    private func apply(_ presentation: RoutePresentation, to route: AnyRoute) -> RouteResolution {
        switch presentation {
        case .push:
            path.append(route)
        case .sheet, .fullScreenCover:
            guard !modalStack.contains(where: { $0.route == route }) else { return .failed(.presentationBusy) }
            let node = deepestNode
            node.modal = .init(route: route, presentation: presentation, child: node.makeChild(for: route))
        case .selection:
            selection = route
        }
        return .resolved(presentation)
    }
    
    private func makeChild(for route: AnyRoute) -> RouterNode {
        .init(scope: route.base.scope() ?? DefaultScope(), parent: self)
    }
    
    public struct Presented: Identifiable {
        
        public let route: AnyRoute
        public let presentation: RoutePresentation
        public let child: RouterNode
        
        public var id: AnyHashable { route.id }
    }
}
