import Foundation
@preconcurrency import SwiftData

enum ModelSchema: VersionedSchema {
    
    static let models: [any PersistentModel.Type] = [
        User.self,
        Workout.self,
        WorkoutRouteDataSample.self,
        WorkoutHeartRateDataSample.self,
        WorkoutPause.self,
        WorkoutEvent.self,
        SyncServiceMapping.self,
        SyncServiceState.self,
    ]
    static let versionIdentifier = Schema.Version(2, 0, 0)
}
