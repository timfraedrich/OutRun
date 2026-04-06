import SwiftUI

struct ActionButtonStyle: PrimitiveButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            GlassProminentButtonStyle()
                .makeBody(configuration: configuration)
                
        } else {
            BorderedProminentButtonStyle()
                .makeBody(configuration: configuration)
                .buttonBorderShape(.roundedRectangle(radius: .regular))
        }
    }
}

extension PrimitiveButtonStyle where Self == ActionButtonStyle {
    static var action: Self { .init() }
}
