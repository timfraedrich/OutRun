import Foundation
import SwiftData

@Model
public class SyncServiceMapping: SyncServiceMappingProtocol {
    
    public var serviceIdentifier: String
    public var externalId: String?
    public var externalUrl: String?
    public var lastEditDateSynced: Date?
    public var syncStatus: WorkoutSyncStatus
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public init(
        serviceIdentifier: String,
        externalId: String?,
        externalUrl: String?,
        lastEditDateSynced: Date?,
        syncStatus: WorkoutSyncStatus,
        workout: Workout? = nil
    ) {
        self.serviceIdentifier = serviceIdentifier
        self.externalId = externalId
        self.externalUrl = externalUrl
        self.lastEditDateSynced = lastEditDateSynced
        self.syncStatus = syncStatus
        self.workout = workout
    }
    
    public convenience init(from rawServiceMapping: RawSyncServiceMapping, attachTo workout: Workout? = nil) {
        self.init(
            serviceIdentifier: rawServiceMapping.serviceIdentifier,
            externalId: rawServiceMapping.externalId,
            externalUrl: rawServiceMapping.externalUrl,
            lastEditDateSynced: rawServiceMapping.lastEditDateSynced,
            syncStatus: rawServiceMapping.syncStatus,
            workout: workout
        )
    }
}
