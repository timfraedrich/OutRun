import Foundation

public struct RawWorkout: Codable, Sendable, WorkoutProtocol {
    
    public var id: UUID
    public var type: WorkoutType
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
    public var sourceService: WorkoutService
    
    public var heartRates: [RawWorkoutHeartRateDataSample]
    public var route: [RawWorkoutRouteDataSample]
    public var pauses: [RawWorkoutPause]
    public var events: [RawWorkoutEvent]
    public var serviceMappings: [RawWorkoutServiceMapping]
    
    public init(
        id: UUID,
        type: WorkoutType,
        distance: Double,
        startDate: Date,
        endDate: Date?,
        energy: Double?,
        repetitions: Int?,
        isRace: Bool,
        name: String?,
        comment: String?,
        creationDate: Date,
        lastEditDate: Date,
        sourceService: WorkoutService,
        heartRates: [RawWorkoutHeartRateDataSample] = [],
        route: [RawWorkoutRouteDataSample] = [],
        pauses: [RawWorkoutPause] = [],
        events: [RawWorkoutEvent] = [],
        serviceMappings: [RawWorkoutServiceMapping] = []
    ) {
        self.id = id
        self.type = type
        self.distance = distance
        self.startDate = startDate
        self.endDate = endDate
        self.energy = energy
        self.repetitions = repetitions
        self.isRace = isRace
        self.name = name
        self.comment = comment
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate
        self.sourceService = sourceService
        self.heartRates = heartRates
        self.route = route
        self.pauses = pauses
        self.events = events
        self.serviceMappings = serviceMappings
    }
    
    public init(workout: Workout) {
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
            sourceService: workout.sourceService,
            heartRates: workout.heartRates.map(RawWorkoutHeartRateDataSample.init).sorted(using: SortDescriptor(\.timestamp)),
            route: workout.route.map(RawWorkoutRouteDataSample.init).sorted(using: SortDescriptor(\.timestamp)),
            pauses: workout.pauses.map(RawWorkoutPause.init).sorted(using: SortDescriptor(\.startDate)),
            events: workout.events.map(RawWorkoutEvent.init).sorted(using: SortDescriptor(\.timestamp)),
            serviceMappings: workout.serviceMappings.map(RawWorkoutServiceMapping.init).sorted(using: SortDescriptor(\.externalId))
        )
    }
}
