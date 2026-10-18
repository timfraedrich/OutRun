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
