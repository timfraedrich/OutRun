import Foundation
import OutRunCore

enum MainSheetDestination: Hashable, Identifiable {
    
    case calendar
    case recording
    case settings
    case workoutDetails(id: Workout.ID)
    
    var id: Int { hashValue }
}
