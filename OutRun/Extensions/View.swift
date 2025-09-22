import SwiftUI

extension View {
    
    @ViewBuilder
    func errorPopover<E: Error>(_ errorBinding: Binding<E?>) -> some View {
        let showErrorBinding = Binding(
            get: { errorBinding.wrappedValue != nil },
            set: { _ in errorBinding.wrappedValue = nil }
        )
        popover(isPresented: showErrorBinding) {
            if let error = errorBinding.wrappedValue {
                Text(error.localizedDescription).frame(idealWidth: 240).padding(.regular).presentationCompactAdaptation(.popover)
            }
        }
    }
    
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
