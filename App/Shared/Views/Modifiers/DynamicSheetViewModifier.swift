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

struct DynamicSheetViewModifier<SheetContent: View>: ViewModifier {
    
    @Binding private var isPresented: Bool
    @State private var sheetContentHeight: CGFloat?
    private let onDismiss: (() -> Void)?
    private let sheetContent: () -> SheetContent
    
    private var presentationDetents: Set<PresentationDetent> {
        if let sheetContentHeight {
            [.height(sheetContentHeight)]
        } else {
            [.fraction(0.999)]
        }
    }
    
    init(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = .none, @ViewBuilder sheetContent: @escaping () -> SheetContent) {
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        self.sheetContent = sheetContent
    }
    
    init<Item: Identifiable, ItemSheetContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = .none,
        @ViewBuilder sheetContent: @escaping (Item) -> ItemSheetContent
    ) where SheetContent == ItemSheetContent? {
        self.init(
            isPresented: .init {
                item.wrappedValue != nil
            } set: { newValue in
                guard !newValue else { return }
                item.wrappedValue = nil
            },
            onDismiss: onDismiss,
            sheetContent: {
                if let value = item.wrappedValue {
                    sheetContent(value)
                }
            }
        )
    }
    
    func body(content: Content) -> some View {
        content.sheet(isPresented: _isPresented, onDismiss: onDismiss) {
            sheetContent()
                .geometryBackground { sheetContentHeight = $0.size.height }
                .presentationDetents(presentationDetents)
        }
    }
}

extension View {
    
    func dynamicSheet<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = .none,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(DynamicSheetViewModifier(isPresented: isPresented, onDismiss: onDismiss, sheetContent: content ))
    }
    
    func dynamicSheet<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = .none,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(DynamicSheetViewModifier(item: item, onDismiss: onDismiss, sheetContent: content))
    }
}
