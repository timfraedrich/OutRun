import SwiftUI

struct CompatibleRegularGlassEffectViewModifier<ClipShape: Shape>: ViewModifier {
    
    private let clipShape: ClipShape
    
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(in: clipShape)
        } else {
            content.background(.background).clipShape(clipShape)
        }
    }
    
    init(clipShape: ClipShape) {
        self.clipShape = clipShape
    }
}

extension View {
    
    @ViewBuilder
    func compatibleRegularGlassEffect<ClipShape: Shape>(in clipShape: ClipShape) -> some View {
        modifier(CompatibleRegularGlassEffectViewModifier(clipShape: clipShape))
    }
}
