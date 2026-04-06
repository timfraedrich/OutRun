import OutRunCore

enum MainSheetDestination: Hashable, Identifiable {
    
    case settings
    case recording
    case workoutDetails(id: Workout.ID)
    
    var id: Int { hashValue }
}
