import SwiftUI

struct MapOverlayBackground: View {
    
    var body: some View {
        if #available(iOS 26, *) {
            Color.clear
                .glassEffect(.regular, in: .rect(cornerRadii: .init(topLeading: 24, topTrailing: 24)))
                .ignoresSafeArea()
        } else {
            Rectangle()
                .fill(.regularMaterial)
                .clipShape(.rect(cornerRadii: .init(topLeading: 24, topTrailing: 24)))
                .ignoresSafeArea()
        }
    }
}
