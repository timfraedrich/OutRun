import SwiftUI

enum CornerRadius: CGFloat {
    
    case extraSmall
    case small
    case regular
    case large
    case extraLarge
    
    var rawValue: CGFloat {
        if #available(iOS 26.0, *) {
            switch self {
            case .extraSmall: 6
            case .small: 12
            case .regular: 24
            case .large: 36
            case .extraLarge: 48
            }
        } else {
            switch self {
            case .extraSmall: 4
            case .small: 8
            case .regular: 16
            case .large: 24
            case .extraLarge: 32
            }
        }
    }
}
