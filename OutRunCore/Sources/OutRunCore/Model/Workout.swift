import Foundation
import SwiftData

@Model
public class Workout: WorkoutProtocol {
    
    @Attribute(.unique, .preserveValueOnDeletion) public private(set) var id: UUID
    
    public private(set) var rawType: WorkoutType.RawValue
    public var distance: Double
    public var startDate: Date
    public var endDate: Date?
    public var energy: Double?
    public var repetitions: Int?
    public var isRace: Bool
    
    public var name: String?
    public var comment: String?
    public var creationDate: Date
    public var lastEditDate: Date
    @Attribute(.preserveValueOnDeletion) public private(set) var rawSource: WorkoutSource.RawValue
    
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
    public convenience init(from workout: any WorkoutProtocol) {
        self.init(
            id: workout.id,
            type: workout.type,
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: workout.energy,
            repetitions: workout.repetitions,
            isRace: workout.isRace,
            name: workout.name,
            comment: workout.comment,
            creationDate: workout.creationDate,
            lastEditDate: workout.lastEditDate,
            source: workout.source
        )
    }
}
