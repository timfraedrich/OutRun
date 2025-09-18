import CoreGraphics

enum Spacing: CGFloat {
    
    case extraSmall
    case small
    case regular
    case large
    case extraLarge
    
    var rawValue: CGFloat {
        switch self {
        case .extraSmall: 4
        case .small: 8
        case .regular: 16
        case .large: 24
        case .extraLarge: 32
        }
    }
}
