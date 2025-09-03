import Foundation

public protocol WorkoutProtocol: Identifiable, Equatable {
    
    associatedtype WorkoutHeartRateDataSampleType: WorkoutHeartRateDataSampleProtocol
    associatedtype WorkoutRouteDataSampleType: WorkoutRouteDataSampleProtocol
    associatedtype WorkoutPauseType: WorkoutPauseProtocol
    associatedtype WorkoutEventType: WorkoutEventProtocol
    associatedtype WorkoutServiceMappingType: WorkoutServiceMappingProtocol
    
    var id: UUID { get }
    var type: WorkoutType { get }
    var distance: Double { get }
    var startDate: Date { get }
    var endDate: Date? { get }
    var energy: Double? { get }
    var repetitions: Int? { get }
    var isRace: Bool { get }
    var name: String? { get }
    var comment: String? { get }
    var creationDate: Date { get }
    var lastEditDate: Date { get }
    var sourceService: WorkoutService { get }
    var heartRates: [WorkoutHeartRateDataSampleType] { get }
    var route: [WorkoutRouteDataSampleType] { get }
    var pauses: [WorkoutPauseType] { get }
    var events: [WorkoutEventType] { get }
    var serviceMappings: [WorkoutServiceMappingType] { get }
}
