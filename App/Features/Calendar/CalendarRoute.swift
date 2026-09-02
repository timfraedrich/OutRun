import SwiftUI
import TFRouting

struct CalendarRoute: RouteProtocol {
    
    func content(in context: RouteContext) -> some View {
        CalendarScene()
    }
    
    func scope() -> (any RoutingScope)? {
        CalendarRoutingScope()
    }
}
