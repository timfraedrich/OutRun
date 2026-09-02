public extension RouteProtocol {
    
    func eraseToAnyRoute() -> AnyRoute {
        AnyRoute(self)
    }
}
