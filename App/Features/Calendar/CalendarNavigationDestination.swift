import Foundation
import OutRunCore

enum CalendarNavigationDestination: Hashable {
    
    case workoutDetails(id: Workout.ID)
    case workoutSelection(between: Date, and: Date)
}
