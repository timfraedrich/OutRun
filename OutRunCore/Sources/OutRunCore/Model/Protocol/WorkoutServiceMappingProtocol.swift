import Foundation

public protocol SyncServiceMappingProtocol: Equatable {
    
    var serviceIdentifier: String { get }
    var externalId: String? { get }
    var externalUrl: String? { get }
    var lastEditDateSynced: Date? { get }
    var syncStatus: WorkoutSyncStatus { get }
}
