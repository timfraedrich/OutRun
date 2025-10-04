import Foundation
import SwiftData

@Model
public class WorkoutServiceMapping: WorkoutServiceMappingProtocol {
    
    public var service: WorkoutService
    public var externalId: String
    public var externalUrl: String?
    public var lastSyncDate: Date?
    public var syncStatus: WorkoutSyncStatus
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(
        service: WorkoutService,
        externalId: String,
        externalUrl: String?,
        lastSyncDate: Date?,
        syncStatus: WorkoutSyncStatus,
        workout: Workout? = nil
    ) {
        self.service = service
        self.externalId = externalId
        self.externalUrl = externalUrl
        self.lastSyncDate = lastSyncDate
        self.syncStatus = syncStatus
        self.workout = workout
    }
    
    public convenience init(from rawServiceMapping: RawWorkoutServiceMapping, attachTo workout: Workout? = nil) {
        self.init(
            service: rawServiceMapping.service,
            externalId: rawServiceMapping.externalId,
            externalUrl: rawServiceMapping.externalUrl,
            lastSyncDate: rawServiceMapping.lastSyncDate,
            syncStatus: rawServiceMapping.syncStatus,
            workout: workout
        )
    }
}
