import OutRunCore

extension WorkoutSource {
    
    var localized: String {
        switch self {
        case .syncService(HealthSyncService.identifier):
            .init(localized: "workout_source_apple_health")
        default:
            description
        }
    }
}
