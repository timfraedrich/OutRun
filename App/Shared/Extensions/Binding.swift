//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

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
