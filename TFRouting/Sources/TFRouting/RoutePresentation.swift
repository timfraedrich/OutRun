public enum RoutePresentation: Hashable, Sendable {
    
    case push
    case sheet
    case fullScreenCover
    /// Names one of the deciding context's parallel branches.
    case selection
    
    public var isModal: Bool {
        switch self {
        case .push, .selection: false
        case .sheet, .fullScreenCover: true
        }
    }
    
    public var isSheet: Bool {
        switch self {
        case .sheet: true
        case .push, .fullScreenCover, .selection: false
        }
    }
}
