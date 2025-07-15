import Foundation
@preconcurrency import SwiftData

enum ModelSchema: VersionedSchema {
    
    static let models: [any PersistentModel.Type] = [
        Workout.self,
        WorkoutRouteDataSample.self,
        WorkoutHeartRateDataSample.self,
        WorkoutPause.self,
        WorkoutEvent.self
    ]
    static let versionIdentifier = Schema.Version(2, 0, 0)
}
