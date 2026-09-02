import SwiftUI
import TFRouting

struct WorkoutSelectionRoute: RouteProtocol {
    
    let startDate: Date
    let endDate: Date
    
    init(between startDate: Date, and endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
    
    func content(in context: RouteContext) -> some View {
        WorkoutSelectionScene(between: startDate, and: endDate)
    }
}
