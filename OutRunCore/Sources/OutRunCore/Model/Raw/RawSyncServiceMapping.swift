import Foundation

public struct RawSyncServiceMapping: Codable, Sendable, SyncServiceMappingProtocol {
    
    public var serviceIdentifier: String
    public var externalId: String?
    public var externalUrl: String?
    public var lastEditDateSynced: Date?
    public var syncStatus: WorkoutSyncStatus
    
    public init(
        serviceIdentifier: String,
        externalId: String? = nil,
        externalUrl: String? = nil,
        lastEditDateSynced: Date? = nil,
        syncStatus: WorkoutSyncStatus = .pending
    ) {
        self.serviceIdentifier = serviceIdentifier
        self.externalId = externalId
        self.externalUrl = externalUrl
        self.lastEditDateSynced = lastEditDateSynced
        self.syncStatus = syncStatus
    }
    
    public init(from mapping: any SyncServiceMappingProtocol) {
        self.init(
            serviceIdentifier: mapping.serviceIdentifier,
            externalId: mapping.externalId,
            externalUrl: mapping.externalUrl,
            lastEditDateSynced: mapping.lastEditDateSynced,
            syncStatus: mapping.syncStatus
        )
    }
}
