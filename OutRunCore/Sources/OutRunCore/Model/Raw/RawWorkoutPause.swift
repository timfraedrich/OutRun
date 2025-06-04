import Foundation

public struct RawWorkoutPause: Codable, Equatable {
    
    public var uuid: UUID
    public var startDate: Date
    public var endDate: Date
    public var userInitiated: Bool
    
    public init(uuid: UUID, startDate: Date, endDate: Date, userInitiated: Bool) {
        self.uuid = uuid
        self.startDate = startDate
        self.endDate = endDate
        self.userInitiated = userInitiated
    }
}
