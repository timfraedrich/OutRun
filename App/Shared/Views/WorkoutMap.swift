import MapKit
import OutRunCore
import SwiftUI

struct WorkoutMap<Content: MapContent>: View {
    
    @Namespace private var mapScope
    private let mapStyle: MapStyle
    private let padding: Spacing
    private let content: () -> Content
    
    init(mapStyle: MapStyle, padding: Spacing, @MapContentBuilder content: @escaping () -> Content) {
        self.mapStyle = mapStyle
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        ZStack {
            Map(scope: mapScope, content: content)
                .mapControls(EmptyView.init)
                .mapStyle(mapStyle)
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
