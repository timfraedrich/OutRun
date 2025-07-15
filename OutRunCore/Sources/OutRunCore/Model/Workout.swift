import Foundation
import SwiftData

@Model
public class Workout: Equatable, Identifiable {
    
    @Attribute(.unique) public private(set) var id: UUID
    public var type: WorkoutType
    public var distance: Double
    public var steps: Int?
    // avg heartrate ?
    public var startDate: Date
    public var endDate: Date?
    /// - Note: burned energy is provided as kcal
    public var burnedEnergy: Double?
    public var isRace: Bool
    public var comment: String?
    public var creationDate: Date
    public var lastEditDate: Date
    // health id ?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutRouteDataSample.workout) public var route: [WorkoutRouteDataSample] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutHeartRateDataSample.workout) public var heartRates: [WorkoutHeartRateDataSample] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutPause.workout) public var pauses: [WorkoutPause] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEvent.workout) public var events: [WorkoutEvent] = []
    
    public init(
        id: UUID = .init(),
        type: WorkoutType,
        distance: Double,
        steps: Int? = nil,
        startDate: Date,
        endDate: Date?,
        burnedEnergy: Double? = nil,
        isRace: Bool,
        comment: String? = nil,
        creationDate: Date,
        lastEditDate: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.distance = distance
        self.steps = steps
        self.startDate = startDate
        self.endDate = endDate
        self.burnedEnergy = burnedEnergy
        self.isRace = isRace
        self.comment = comment
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate ?? creationDate
    }
}
