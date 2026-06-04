import MapKit
import OutRunCore
import SwiftUI

struct WorkoutMap<Content: MapContent>: View {
    
    @Namespace private var mapScope
    @State private var lastSetPosition: MapCameraPosition = .automatic
    @Binding private var keepUserCentered: Bool
    private let style: MapStyle
    private let padding: Spacing
    private let content: () -> Content
    
    private var position: Binding<MapCameraPosition> {
        .init {
            keepUserCentered ? .userLocation(fallback: .automatic) : lastSetPosition
        } set: { position in
            lastSetPosition = position
            keepUserCentered = false
        }
    }
    
    init(keepUserCentered: Binding<Bool>, style: MapStyle = .standard, padding: Spacing, @MapContentBuilder content: @escaping () -> Content) {
        self._keepUserCentered = keepUserCentered
        self.style = style
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        ZStack {
            Map(position: position, scope: mapScope, content: content)
                .mapControls(EmptyView.init)
                .mapStyle(style)
            MapScaleView(scope: mapScope)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.regular)
            MapCompass(scope: mapScope)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding([.top, .trailing], padding)
        }
        .mapScope(mapScope)
    }
}
