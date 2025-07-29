import Foundation

public struct RawWorkoutServiceMapping: Codable, Equatable {
    
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
}