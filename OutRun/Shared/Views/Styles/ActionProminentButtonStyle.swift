import SwiftUI

struct ActionProminentButtonStyle: PrimitiveButtonStyle {
    
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

extension PrimitiveButtonStyle where Self == ActionProminentButtonStyle {
    static var actionProminent: Self { .init() }
}
