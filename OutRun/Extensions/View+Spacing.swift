import SwiftUI

extension View {
    
    @ViewBuilder
    func padding(_ length: Spacing) -> some View {
        self.padding(length.rawValue)
    }
    
    @ViewBuilder
    func padding(_ edges: Edge.Set = .all, _ length: Spacing) -> some View {
        self.padding(edges, length.rawValue)
    }
}
