import SwiftUI

extension Binding {
    
    func existenceBinding<V: Sendable>() -> Binding<Bool> where Value == Optional<V> {
        .init {
            wrappedValue != nil
        } set: { _ in
            wrappedValue = nil
        }
    }
    
    @MainActor
    static func variable(_ value: Value) -> Self {
        Variable(value: value).binding
    }
    
    @MainActor
    private class Variable {
        
        var value: Value
        
        init(value: Value) {
            self.value = value
        }
        
        var binding: Binding<Value> {
            Binding(
                get: { self.value },
                set: { newValue in self.value = newValue }
            )
        }
    }
}
