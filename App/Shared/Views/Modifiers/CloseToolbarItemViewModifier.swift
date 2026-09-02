import SwiftUI

private struct CloseToolbarItemViewModifier: ViewModifier {
    
    @Environment(\.dismiss) private var dismiss
    let active: Bool
    
    func body(content: Content) -> some View {
        if active {
            content.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("close", systemImage: "xmark", action: dismiss.callAsFunction)
                }
            }
        } else {
            content
        }
    }
}

extension View {
    
    @ViewBuilder
    func closeToolbarItem(active: Bool = true) -> some View {
        modifier(CloseToolbarItemViewModifier(active: active))
    }
}
