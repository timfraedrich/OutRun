import Foundation

public protocol WorkoutProtocol: Identifiable, Equatable {
    
    associatedtype WorkoutHeartRateDataSampleType: WorkoutHeartRateDataSampleProtocol
    associatedtype WorkoutRouteDataSampleType: WorkoutRouteDataSampleProtocol
    associatedtype WorkoutPauseType: WorkoutPauseProtocol
    associatedtype WorkoutEventType: WorkoutEventProtocol
    associatedtype SyncServiceMappingType: SyncServiceMappingProtocol
    
    var id: UUID { get }
    var type: WorkoutType { get }
    /// - note: Distance is provided in metres.
    var distance: Double { get }
    var startDate: Date { get }
    var endDate: Date? { get }
    /// - note: Energy is provided in joules, if nil no energy was recorded.
    var energy: Double? { get }
    /// - note: Repetitions can be steps or cycle strokes depending on the workout type.
    var repetitions: Int? { get }
    var isRace: Bool { get }
    var name: String? { get }
    var comment: String? { get }
    var creationDate: Date { get }
    var lastEditDate: Date { get }
    var source: WorkoutSource { get }
    var heartRates: [WorkoutHeartRateDataSampleType] { get }
    var route: [WorkoutRouteDataSampleType] { get }
    var pauses: [WorkoutPauseType] { get }
    var events: [WorkoutEventType] { get }
    var serviceMappings: [SyncServiceMappingType] { get }
}
