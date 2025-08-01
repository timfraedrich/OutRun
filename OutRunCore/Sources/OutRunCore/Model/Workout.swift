import Foundation
import SwiftData

@Model
public class Workout: Equatable, Identifiable {
    
    @Attribute(.unique) public private(set) var id: UUID
    
    public var type: WorkoutType
    /// - note: Distance is provided in metres.
    public var distance: Double
    public var startDate: Date
    public var endDate: Date?
    /// - note: Energy is provided in joules, if nil no energy was recorded.
    public var energy: Double?
    public var steps: Int?
    public var isRace: Bool
    
    public var name: String?
    public var comment: String?
    public var creationDate: Date
    public var lastEditDate: Date
    public var sourceService: WorkoutService
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutRouteDataSample.workout) public var route: [WorkoutRouteDataSample] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutHeartRateDataSample.workout) public var heartRates: [WorkoutHeartRateDataSample] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutPause.workout) public var pauses: [WorkoutPause] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEvent.workout) public var events: [WorkoutEvent] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutServiceMapping.workout) public var serviceMappings: [WorkoutServiceMapping] = []
    
    public init(
        id: UUID = .init(),
        type: WorkoutType,
        distance: Double,
        startDate: Date,
        endDate: Date?,
        energy: Double?,
        steps: Int?,
        isRace: Bool,
        name: String?,
        comment: String? = nil,
        creationDate: Date,
        lastEditDate: Date? = nil,
        sourceService: WorkoutService
    ) {
        self.id = id
        self.type = type
        self.distance = distance
        self.startDate = startDate
        self.endDate = endDate
        self.energy = energy
        self.steps = steps
        self.isRace = isRace
        self.name = name
        self.comment = comment
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate ?? creationDate
        self.sourceService = sourceService
    }
    
    /// - note: this initializer leaves out any kind of samples. Samples must be inserted into the context and linked
    /// manually.
    convenience init(from rawWorkout: RawWorkout) {
        self.init(
            id: rawWorkout.id,
            type: rawWorkout.type,
            distance: rawWorkout.distance,
            startDate: rawWorkout.startDate,
            endDate: rawWorkout.endDate,
            energy: rawWorkout.energy,
            steps: rawWorkout.steps,
            isRace: rawWorkout.isRace,
            name: rawWorkout.name,
            comment: rawWorkout.comment,
            creationDate: rawWorkout.creationDate,
            lastEditDate: rawWorkout.lastEditDate,
            sourceService: rawWorkout.sourceService
        )
    }
}
