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
