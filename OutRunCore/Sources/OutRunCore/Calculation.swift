import Foundation
import NIOCore

public enum Calculation {
    
    // TODO: Use more advanced energy calculation.
    /// - returns: The calculated energy in joules.
    static func calculateBurnedEnergy(weight: Double?, distance: Double, workoutType: WorkoutType) -> Double? {
        guard let weight else { return nil }
        // calories == MET ( speed ( kilometers / hours ) * METSpeedMultiplier ) * weight * hours
        //          == kilometers / hours * METSpeedMultiplier * weight * hours
        //          == kilometers * METSpeedMultiplier * weight
        let kcalValue = distance / 1000 * workoutType.METSpeedMultiplier * weight
        return UnitEnergy.kilocalories.converter.baseUnitValue(fromValue: kcalValue)
    }
    
    static func calculateBaseSpeedUnitValue(kilometersPerHour: Double) -> Double {
        UnitSpeed.kilometersPerHour.converter.baseUnitValue(fromValue: kilometersPerHour)
    }
    
    typealias ElevationTouple = (ascent: Float, descent: Float)
    
    /// Computes the elevation changes (ascending and descending) from altitudes of a workouts route
    /// - parameter altitudes: the provided elevations from the route data samples
    /// - returns: Returns the calculated ascending and descending altitude in a touple of two values if the altitudes collection had at
    /// least two values.
    static func calculateElevationData(from altitudes: [Float]) -> ElevationTouple? {
        guard !altitudes.isEmpty, altitudes.count > 1 else { return nil }
        var ascent: Float = 0, descent: Float = 0
        let threshold: Float = 0.5 // a threshold to filter slight variation due to measurment errors
        var lastConsideredRoundedAltitude: Float?
        for i in altitudes.indices {
            var sum: Float = 0, count: Float = 0
            for j in (i - 5)...(i + 5) where j >= 0 && j < altitudes.count {
                sum += altitudes[j]
                count += 1
            }
            let roundedAltitude = (sum / count)
            guard let lastRounded = lastConsideredRoundedAltitude else {
                lastConsideredRoundedAltitude = roundedAltitude
                continue
            }
            let difference = roundedAltitude - lastRounded
            guard abs(difference) >= threshold else { continue }
            if difference > 0 {
                ascent += difference
            } else if difference < 0 {
                descent += -difference
            }
            lastConsideredRoundedAltitude = roundedAltitude
        }
        return (ascent, descent)
    }
    
    static func calculatePauseDuration(pauses: [any WorkoutPauseProtocol]) -> TimeInterval {
        pauses.reduce(TimeInterval(), { $0 + $1.duration })
    }
    
    static func calculateActiveDuration(startDate: Date, endDate: Date?, pauses: [any WorkoutPauseProtocol]) -> TimeInterval? {
        guard let endDate else { return nil }
        return startDate.distance(to: endDate) - calculatePauseDuration(pauses: pauses)
    }
    
    static func calculateAverageSpeed(distance: Double, startDate: Date, endDate: Date?, pauses: [any WorkoutPauseProtocol]) -> Measurement<UnitSpeed> {
        let activeDuration = calculateActiveDuration(startDate: startDate, endDate: endDate, pauses: pauses)
        return calculateAverageSpeed(distance: distance, activeDuration: activeDuration)
    }
    
    static func calculateAverageSpeed(distance: Double, activeDuration: TimeInterval?) -> Measurement<UnitSpeed> {
        guard let activeDuration, activeDuration > 0, distance > 0
        else { return .init(value: 0, unit: .metersPerSecond) }
        return .init(value: distance / activeDuration, unit: .metersPerSecond)
    }
    
    static func calculateTopSpeed(route: [any WorkoutRouteDataSampleProtocol]) -> Measurement<UnitSpeed>? {
        var topSpeed: Float?
        for routeSample in route where routeSample.speed > 0 {
            guard topSpeed == nil || routeSample.speed > topSpeed ?? 0 else { continue }
            topSpeed = routeSample.speed
        }
        guard let topSpeed else { return nil }
        return .init(value: Double(topSpeed), unit: .metersPerSecond)
    }
    
    static func calculateEnergyPerMinute(energy: Double?, startDate: Date, endDate: Date?, pauses: [any WorkoutPauseProtocol]) -> Measurement<UnitEnergy>? {
        guard let energy, let activeDuration = calculateActiveDuration(startDate: startDate, endDate: endDate, pauses: pauses)
        else { return nil }
        let minutes = UnitDuration.minutes.converter.value(fromBaseUnitValue: activeDuration)
        return .init(value: energy / minutes, unit: .joules)
    }
    
    static func calculateElevationData(from route: [any WorkoutRouteDataSampleProtocol]) -> Calculation.ElevationTouple? {
        let altitudes = route.compactMap({ $0.altitude > 0 ? $0.altitude : nil })
        return Calculation.calculateElevationData(from: altitudes)
    }
    
    /**
     Computes pauses from workout event data.
     - parameter events: The events from which the pauses are supposed to be calculated
     - parameter workoutStart: The start date of the workout to which the pauses are linked
     - parameter workoutEnd: The start date of the workout to which the pauses are linked
     - parameter minimumDuration: The minimum duration of a pause object. Objects with smaller duration will be filtered out. Provided
       values must be larger than 0.
     - returns: The calculated pause objects
     - complexity: O(*n* log *n*) in the number of events *n*.
     
     Workout event data might be inconsistent, in which case we try to recover pauses as follows:
     - Pauses that extend over the start or end of the workout (start...end) get trimmed at the start or end.
     - Overlapping pauses get merged if their types match
     - User initiated pauses take precedence over automatic pauses
     - Pauses of duration under 1s are ignored
     
     To illustrate, here is an example with user initiated (+) and automatic pauses (\*):
     ```
       start.................................end
     
       |---------------ORIGINAL----------------|
     
            +++++++             ++++
                         +++++++++
     ***     *****            *******        *****
     
       |---------------CONVERTED---------------|
     
            +++++++      +++++++++++         ***
     ```
     */
    public static func calculatePauses(
        from events: [PauseEvent],
        workoutStart: Date,
        workoutEnd: Date,
        minimumDuration: TimeInterval = .leastNonzeroMagnitude
    ) -> [RawWorkoutPause] {
        let sortedEvents = events
            .map { PauseEvent(date: max(workoutStart, min(workoutEnd, $0.date)), type: $0.type) }
            .sorted { $0.date < $1.date }
        var pauses = [RawWorkoutPause]()
        var pauseStarts = CircularBuffer<Date>(initialCapacity: sortedEvents.count)
        var autoPauseStarts = CircularBuffer<Date>(initialCapacity: sortedEvents.count)
        for pauseEvent in sortedEvents {
            switch pauseEvent.type {
            case .pause:
                if pauseStarts.isEmpty, let firstAutoPauseStart = autoPauseStarts.first {
                    pauses.append(.init(startDate: firstAutoPauseStart, endDate: pauseEvent.date, userInitiated: false))
                }
                pauseStarts.append(pauseEvent.date)
            case .autoPause:
                autoPauseStarts.append(pauseEvent.date)
            case .resume:
                guard let start = pauseStarts.popLast(), pauseStarts.isEmpty else { continue }
                pauses.append(.init(startDate: start, endDate: pauseEvent.date, userInitiated: true))
            case .autoResume:
                guard let potentialStart = autoPauseStarts.popLast(), autoPauseStarts.isEmpty, pauseStarts.isEmpty else { continue }
                let start = if let lastPauseEnd = pauses.last?.endDate { max(potentialStart, lastPauseEnd) } else { potentialStart }
                pauses.append(.init(startDate: start, endDate: pauseEvent.date, userInitiated: false))
            }
        }
        if let pauseStart = pauseStarts.first {
            pauses.append(.init(startDate: pauseStart, endDate: workoutEnd, userInitiated: true))
        } else if let autoPauseStart = autoPauseStarts.first {
            pauses.append(.init(startDate: autoPauseStart, endDate: workoutEnd, userInitiated: false))
        }
        let safeMinimumDuration = max(minimumDuration, .leastNonzeroMagnitude)
        return pauses.filter { $0.duration >= safeMinimumDuration }
    }
    
    // MARK: Types
    
    public struct PauseEvent {
        
        public let date: Date
        public let type: PauseEventType
        
        public init(date: Date, type: PauseEventType) {
            self.date = date
            self.type = type
        }
    }
    
    public enum PauseEventType: Int {
        case pause = 0
        case autoPause = 1
        case resume = 2
        case autoResume = 3
        
        public var isPauseStart: Bool {
            switch self {
            case .pause, .autoPause: true
            case .resume, .autoResume: false
            }
        }
    }
}
