/// - note: `@unchecked` because `AnyHashable` is not `Sendable` itself; the value it wraps is, as
/// ``RouteProtocol`` refines `Sendable`.
public struct AnyRoute: Identifiable, Hashable, @unchecked Sendable {
    
    public let base: any RouteProtocol
    private let erased: AnyHashable
    
    public var id: AnyHashable { erased }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.erased == rhs.erased
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(erased)
    }
    
    /// - note: Wrapping the opened existential is what gives the route the identity and equality of its
    /// concrete type.
    public init(_ route: any RouteProtocol) {
        self.base = route
        self.erased = AnyHashable(route)
    }
}
