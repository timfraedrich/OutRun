import Foundation

public protocol WorkoutEventProtocol: Equatable {
    var type: WorkoutEventType { get }
    var timestamp: Date { get }
}