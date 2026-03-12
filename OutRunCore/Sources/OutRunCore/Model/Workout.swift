import Foundation
import SwiftData

@Model
public class Workout: WorkoutProtocol {
    
    @Attribute(.unique, .preserveValueOnDeletion) public private(set) var id: UUID
    
    public private(set) var rawType: WorkoutType.RawValue
    /// - note: Distance is provided in metres.
    public var distance: Double
    public var startDate: Date
    public var endDate: Date?
    /// - note: Energy is provided in joules, if nil no energy was recorded.
    public var energy: Double?
    /// - note: Repetitions can be steps or cycle strokes depending on the workout type.
    public var repetitions: Int?
    public var isRace: Bool
    
    public var name: String?
    public var comment: String?
    public var creationDate: Date
    public var lastEditDate: Date
    public private(set) var rawSource: WorkoutSource.RawValue
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutRouteDataSample.workout) public var route: [WorkoutRouteDataSample] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutHeartRateDataSample.workout) public var heartRates: [WorkoutHeartRateDataSample] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutPause.workout) public var pauses: [WorkoutPause] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEvent.workout) public var events: [WorkoutEvent] = []
    @Relationship(deleteRule: .cascade, inverse: \SyncServiceMapping.workout) public var serviceMappings: [SyncServiceMapping] = []
    
    public var type: WorkoutType {
        get { .init(rawValue: rawType) }
        set { rawType = newValue.rawValue }
    }
    
    public var source: WorkoutSource {
        get { .init(rawValue: rawSource) }
        set { rawSource = newValue.rawValue }
    }
    
    public init(
        id: UUID = .init(),
        type: WorkoutType,
        distance: Double,
        startDate: Date,
        endDate: Date?,
        energy: Double?,
        repetitions: Int?,
        isRace: Bool,
        name: String?,
        comment: String? = nil,
        creationDate: Date,
        lastEditDate: Date? = nil,
        source: WorkoutSource
    ) {
        self.id = id
        self.rawType = type.rawValue
        self.distance = distance
        self.startDate = startDate
        self.endDate = endDate
        self.energy = energy
        self.repetitions = repetitions
        self.isRace = isRace
        self.name = name
        self.comment = comment
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate ?? creationDate
        self.rawSource = source.rawValue
    }
    
    /// - note: this initializer leaves out any kind of samples. Samples must be inserted into the context and linked manually.
    public convenience init(from rawWorkout: RawWorkout) {
        self.init(
            id: rawWorkout.id,
            type: rawWorkout.type,
            distance: rawWorkout.distance,
            startDate: rawWorkout.startDate,
            endDate: rawWorkout.endDate,
            energy: rawWorkout.energy,
            repetitions: rawWorkout.repetitions,
            isRace: rawWorkout.isRace,
            name: rawWorkout.name,
            comment: rawWorkout.comment,
            creationDate: rawWorkout.creationDate,
            lastEditDate: rawWorkout.lastEditDate,
            source: rawWorkout.source
        )
    }
}
