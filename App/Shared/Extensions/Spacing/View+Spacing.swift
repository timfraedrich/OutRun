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
        spacing: Spacing,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        compatibleSafeAreaBar(edge: edge, alignment: alignment, spacing: spacing.rawValue, content: content)
    }
    
    @ViewBuilder
    func padding(_ length: Spacing) -> some View {
        padding(length.rawValue)
    }
    
    @ViewBuilder
    func padding(_ edges: Edge.Set, _ length: Spacing) -> some View {
        padding(edges, length.rawValue)
    }
    
    @ViewBuilder
    func safeAreaPadding(_ length: Spacing) -> some View {
        safeAreaPadding(length.rawValue)
    }
    
    @ViewBuilder
    func safeAreaPadding(_ edges: Edge.Set, _ length: Spacing) -> some View {
        safeAreaPadding(edges, length.rawValue)
    }

    @ViewBuilder
    func contentMargins(_ length: Spacing, for placement: ContentMarginPlacement = .automatic) -> some View {
        contentMargins(length.rawValue, for: placement)
    }
}
