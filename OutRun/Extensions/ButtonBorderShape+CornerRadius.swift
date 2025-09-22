import SwiftUI

extension ButtonBorderShape {
    
    static func roundedRectangle(radius: CornerRadius) -> ButtonBorderShape {
        .roundedRectangle(radius: radius.rawValue)
    }
}
