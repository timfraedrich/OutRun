import Foundation
import SwiftData

@Model
public class SyncServiceMapping: SyncServiceMappingProtocol {
    
    public var serviceIdentifier: String
    public var externalId: String?
    public var externalUrl: String?
    public var lastEditDateSynced: Date?
    public private(set) var rawSyncStatus: WorkoutSyncStatus.RawValue
    
    @Relationship(deleteRule: .nullify) public var workout: Workout?
    
    public var syncStatus: WorkoutSyncStatus {
        get { .init(rawValue: rawSyncStatus) }
        set { rawSyncStatus = newValue.rawValue }
    }
    
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
        self.rawSyncStatus = syncStatus.rawValue
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
