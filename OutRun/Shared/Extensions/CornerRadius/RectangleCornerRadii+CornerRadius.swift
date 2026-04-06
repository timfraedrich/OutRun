import SwiftUI

extension RectangleCornerRadii {
    
    init(
        topLeading: CornerRadius? = .none,
        bottomLeading: CornerRadius? = .none,
        bottomTrailing: CornerRadius? = .none,
        topTrailing: CornerRadius? = .none
    ) {
        self.init(
            topLeading: topLeading?.rawValue ?? .zero,
            bottomLeading: bottomLeading?.rawValue ?? .zero,
            bottomTrailing: bottomTrailing?.rawValue ?? .zero,
            topTrailing: topTrailing?.rawValue ?? .zero
        )
    }
}
