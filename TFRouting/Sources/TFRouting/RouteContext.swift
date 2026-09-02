public struct RouteContext: Hashable, Sendable {
    
    public let presentation: RoutePresentation
    
    /// Signals to a scene that it should offer a close button.
    public var isModalRoot: Bool { presentation.isModal }
    
    public init(presentation: RoutePresentation) {
        self.presentation = presentation
    }
}
