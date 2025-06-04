import Foundation

public struct RawWorkout: Codable, Equatable {
    
    public var uuid: UUID
    public var workoutType: WorkoutType
    public var distance: Double
    public var steps: Int?
    public var startDate: Date
    public var endDate: Date?
    public var burnedEnergy: Double?
    public var isRace: Bool
    public var comment: String?
    public var created: Date
    public var lastModified: Date
    
    public var heartRates: [RawWorkoutHeartRateDataSample]
    public var routeData: [RawWorkoutRouteDataSample]
    public var pauses: [RawWorkoutPause]
    public var workoutEvents: [RawWorkoutEvent]
    
    public init(
        uuid: UUID,
        workoutType: WorkoutType,
        distance: Double,
        steps: Int?,
        startDate: Date,
        endDate: Date?,
        burnedEnergy: Double?,
        isRace: Bool,
        comment: String?,
        created: Date,
        lastModified: Date,
        heartRates: [RawWorkoutHeartRateDataSample],
        routeData: [RawWorkoutRouteDataSample],
        pauses: [RawWorkoutPause],
        workoutEvents: [RawWorkoutEvent]
    ) {
        self.uuid = uuid
        self.workoutType = workoutType
        self.distance = distance
        self.steps = steps
        self.startDate = startDate
        self.endDate = endDate
        self.burnedEnergy = burnedEnergy
        self.isRace = isRace
        self.comment = comment
        self.created = created
        self.lastModified = lastModified
        self.heartRates = heartRates
        self.routeData = routeData
        self.pauses = pauses
        self.workoutEvents = workoutEvents
    }
}
