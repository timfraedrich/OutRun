public struct RouterNodeSnapshot: Sendable {
    
    public let path: [AnyRoute]
    public let isPresentingModally: Bool
    
    public init(path: [AnyRoute], isPresentingModally: Bool) {
        self.path = path
        self.isPresentingModally = isPresentingModally
    }
}
