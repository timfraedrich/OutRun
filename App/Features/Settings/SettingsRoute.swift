import SwiftUI
import TFRouting

struct SettingsRoute: RouteProtocol {
    
    func content(in context: RouteContext) -> some View {
        SettingsScene()
    }
    
    func scope() -> (any RoutingScope)? {
        SettingsRoutingScope()
    }
}
