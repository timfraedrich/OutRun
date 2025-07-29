import Foundation
import SwiftData

@Model
public class WorkoutServiceMapping: Equatable {
    
    public var service: WorkoutService
    public var externalId: String
    public var externalUrl: String?
    public var lastSyncDate: Date?
    public var syncStatus: WorkoutSyncStatus
    
    @Relationship(deleteRule: .nullify) public var workout: Workout
    
    init(
        service: WorkoutService,
        externalId: String,
        externalUrl: String?,
        lastSyncDate: Date,
        syncStatus: WorkoutSyncStatus,
        workout: Workout
    ) {
        self.service = service
        self.externalId = externalId
        self.externalUrl = externalUrl
        self.lastSyncDate = lastSyncDate
        self.syncStatus = syncStatus
        self.workout = workout
    }
}

