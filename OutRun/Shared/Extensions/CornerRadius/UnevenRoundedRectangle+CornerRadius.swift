import SwiftUI

extension UnevenRoundedRectangle {
    
    init(
        topLeadingRadius: CornerRadius? = .none,
        bottomLeadingRadius: CornerRadius? = .none,
        bottomTrailingRadius: CornerRadius? = .none,
        topTrailingRadius: CornerRadius? = .none,
        style: RoundedCornerStyle = .continuous
    ) {
        self.init(
            topLeadingRadius: topLeadingRadius?.rawValue ?? .zero,
            bottomLeadingRadius: bottomLeadingRadius?.rawValue ?? .zero,
            bottomTrailingRadius: bottomTrailingRadius?.rawValue ?? .zero,
            topTrailingRadius: topTrailingRadius?.rawValue ?? .zero,
            style: style
        )
    }
}

extension Shape where Self == UnevenRoundedRectangle {
    
    static func rect(
        topLeadingRadius: CornerRadius? = .none,
        bottomLeadingRadius: CornerRadius? = .none,
        bottomTrailingRadius: CornerRadius? = .none,
        topTrailingRadius: CornerRadius? = .none,
        style: RoundedCornerStyle = .continuous
    ) -> Self {
        .init(
            topLeadingRadius: topLeadingRadius?.rawValue ?? .zero,
            bottomLeadingRadius: bottomLeadingRadius?.rawValue ?? .zero,
            bottomTrailingRadius: bottomTrailingRadius?.rawValue ?? .zero,
            topTrailingRadius: topTrailingRadius?.rawValue ?? .zero,
            style: style
        )
    }
}

extension InsettableShape where Self == UnevenRoundedRectangle {
    
    static func rect(
        topLeadingRadius: CornerRadius? = .none,
        bottomLeadingRadius: CornerRadius? = .none,
        bottomTrailingRadius: CornerRadius? = .none,
        topTrailingRadius: CornerRadius? = .none,
        style: RoundedCornerStyle = .continuous
    ) -> Self {
        .init(
            topLeadingRadius: topLeadingRadius?.rawValue ?? .zero,
            bottomLeadingRadius: bottomLeadingRadius?.rawValue ?? .zero,
            bottomTrailingRadius: bottomTrailingRadius?.rawValue ?? .zero,
            topTrailingRadius: topTrailingRadius?.rawValue ?? .zero,
            style: style
        )
    }
}
