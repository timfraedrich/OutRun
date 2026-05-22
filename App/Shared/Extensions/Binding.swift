import SwiftUI

extension Binding {
    
    func existenceBinding<V: Sendable>() -> Binding<Bool> where Value == Optional<V> {
        .init {
            wrappedValue != nil
        } set: { _ in
            wrappedValue = nil
        }
    }
}
