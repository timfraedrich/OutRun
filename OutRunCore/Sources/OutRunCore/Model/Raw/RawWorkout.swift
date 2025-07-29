import Foundation

public struct RawWorkout: Codable, Equatable, Identifiable {
    
    public var id: UUID
    public var type: WorkoutType
    public var distance: Double
    public var startDate: Date
    public var endDate: Date?
    public var energy: Double?
    public var steps: Int?
    public var isRace: Bool
    public var name: String?
    public var comment: String?
    public var creationDate: Date
    public var lastEditDate: Date
    public var sourceService: WorkoutService
    
    public var heartRates: [RawWorkoutHeartRateDataSample]
    public var routeData: [RawWorkoutRouteDataSample]
    public var pauses: [RawWorkoutPause]
    public var workoutEvents: [RawWorkoutEvent]
    public var serviceMappings: [RawWorkoutServiceMapping]
    
    public init(
        id: UUID,
        type: WorkoutType,
        distance: Double,
        startDate: Date,
        endDate: Date?,
        energy: Double?,
        steps: Int?,
        isRace: Bool,
        name: String?,
        comment: String?,
        creationDate: Date,
        lastEditDate: Date,
        sourceService: WorkoutService,
        heartRates: [RawWorkoutHeartRateDataSample] = [],
        routeData: [RawWorkoutRouteDataSample] = [],
        pauses: [RawWorkoutPause] = [],
        workoutEvents: [RawWorkoutEvent] = [],
        serviceMappings: [RawWorkoutServiceMapping] = []
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
        self.lastEditDate = lastEditDate
        self.sourceService = sourceService
        self.heartRates = heartRates
        self.routeData = routeData
        self.pauses = pauses
        self.workoutEvents = workoutEvents
        self.serviceMappings = serviceMappings
    }
}
