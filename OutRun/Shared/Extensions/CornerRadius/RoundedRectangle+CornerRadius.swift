import SwiftUI

extension RoundedRectangle {
    
    init(cornerRadius: CornerRadius, style: RoundedCornerStyle = .continuous) {
        self.init(cornerRadius: cornerRadius.rawValue, style: style)
    }
}

extension Shape where Self == RoundedRectangle {
    
    static func rect(cornerRadius: CornerRadius, style: RoundedCornerStyle = .continuous) -> Self {
        .init(cornerRadius: cornerRadius, style: style)
    }
}

extension InsettableShape where Self == RoundedRectangle {
    
    static func rect(cornerRadius: CornerRadius, style: RoundedCornerStyle = .continuous) -> Self {
        .init(cornerRadius: cornerRadius, style: style)
    }
}
