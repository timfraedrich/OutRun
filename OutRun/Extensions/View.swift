import SwiftUI

extension View {
    
    @ViewBuilder
    func geometryBackground(_ closure: @escaping (GeometryProxy) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                DispatchQueue.main.async {
                    closure(proxy)
                }
                return Color.clear
            }
        }
    }
}
