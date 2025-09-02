import Foundation

public protocol WorkoutServiceMappingProtocol: Equatable {
    var service: WorkoutService { get }
    var externalId: String { get }
    var externalUrl: String? { get }
    var lastSyncDate: Date? { get }
    var syncStatus: WorkoutSyncStatus { get }
}