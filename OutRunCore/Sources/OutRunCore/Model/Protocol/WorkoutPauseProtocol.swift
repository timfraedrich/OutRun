import Foundation

public protocol WorkoutPauseProtocol: Equatable {
    var startDate: Date { get }
    var endDate: Date { get }
    var userInitiated: Bool { get }
    var duration: TimeInterval { get }
}