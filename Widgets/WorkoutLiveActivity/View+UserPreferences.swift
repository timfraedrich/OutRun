import OutRunCore
import SwiftUI
import WidgetKit

extension View {
    func userPreferences(of context: ActivityViewContext<WorkoutAttributes>) -> some View {
        environment(UserPreferences(preferences: context.state.preferences))
    }
}
