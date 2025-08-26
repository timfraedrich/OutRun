import Foundation

public struct RawWorkoutServiceMapping: Codable, Equatable, Sendable {
    
    public var service: WorkoutService
    public var externalId: String
    public var externalUrl: String?
    public var lastSyncDate: Date?
    public var syncStatus: WorkoutSyncStatus
    
    public init(
        service: WorkoutService,
        externalId: String,
        externalUrl: String?,
        lastSyncDate: Date?,
        syncStatus: WorkoutSyncStatus
    ) {
        self.service = service
        self.externalId = externalId
        self.externalUrl = externalUrl
        self.lastSyncDate = lastSyncDate
        self.syncStatus = syncStatus
    }
    
    public init(from serviceMapping: WorkoutServiceMapping) {
        self.init(
            service: serviceMapping.service,
            externalId: serviceMapping.externalId,
            externalUrl: serviceMapping.externalUrl,
            lastSyncDate: serviceMapping.lastSyncDate,
            syncStatus: serviceMapping.syncStatus
        )
    }
}
