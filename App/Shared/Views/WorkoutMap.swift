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

import MapKit
import OutRunCore
import SwiftUI

struct WorkoutMap<Content: MapContent>: View {
    
    @Namespace private var mapScope
    @State private var lastSetPosition: MapCameraPosition = .automatic
    @Binding private var keepUserCentered: Bool
    private let style: MapStyle
    private let content: () -> Content
    
    private var position: Binding<MapCameraPosition> {
        .init {
            keepUserCentered ? .userLocation(fallback: .automatic) : lastSetPosition
        } set: { position in
            lastSetPosition = position
            keepUserCentered = false
        }
    }
    
    init(keepUserCentered: Binding<Bool>, style: MapStyle = .standard, @MapContentBuilder content: @escaping () -> Content) {
        self._keepUserCentered = keepUserCentered
        self.style = style
        self.content = content
    }
    
    var body: some View {
        ZStack {
            Map(position: position, scope: mapScope, content: content)
                .mapControls(EmptyView.init)
                .mapStyle(style)
            HStack(alignment: .bottom) {
                MapScaleView(scope: mapScope)
                MapCompass(scope: mapScope)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .scenePadding([.bottom, .trailing])
        }
        .mapScope(mapScope)
    }
}
