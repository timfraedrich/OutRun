import SwiftUI
import TFRouting

struct RecordingRoute: RouteProtocol {
    
    func content(in context: RouteContext) -> some View {
        RecordingScene()
    }
}
