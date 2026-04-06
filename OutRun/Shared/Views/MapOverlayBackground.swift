import SwiftUI

struct MapOverlayBackground: View {
    
    var body: some View {
        if #available(iOS 26, *) {
            Color.clear
                .glassEffect(.regular, in: .rect(topLeadingRadius: .large, topTrailingRadius: .large))
                .ignoresSafeArea()
        } else {
            Rectangle()
                .fill(.background)
                .clipShape(.rect(topLeadingRadius: .large, topTrailingRadius: .large))
                .ignoresSafeArea()
        }
    }
}
