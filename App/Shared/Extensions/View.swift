//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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

extension View {
    
    @ViewBuilder
    func compatibleSafeAreaBar<Content: View>(
        edge: VerticalEdge,
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = .none,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: edge, alignment: alignment, spacing: spacing, content: content)
        } else {
            safeAreaInset(edge: edge, alignment: alignment, spacing: spacing) {
                ZStack {
                    BackgroundBlackoutGradient(startPoint: edge == .top ? .bottom : .top, endPoint: .center)
                        .ignoresSafeArea()
                    content()
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    @ViewBuilder
    func compatibleScrollEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectHidden(hidden, for: edges)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func errorAlert<E: Error>(_ errorBinding: Binding<E?>) -> some View {
        alert("error", isPresented: errorBinding.existenceBinding()) {
            Button("dismiss") {}
        } message: {
            if let error = errorBinding.wrappedValue {
                Text(error.localizedDescription)
            }
        }
    }
    
    @ViewBuilder
    func errorPopover<E: Error>(_ errorBinding: Binding<E?>) -> some View {
        popover(isPresented: errorBinding.existenceBinding()) {
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
    
    @ViewBuilder
    func ignoresBottomSafeAreaOnIOS26OrLater(regions: SafeAreaRegions = .all) -> some View {
        if #available(iOS 26.0, *) {
            ignoresSafeArea(regions, edges: .bottom)
        } else {
            self
        }
    }
}
