import Foundation

public enum WorkoutMetric {
    
    case distance
    case ascend
    case descend
    case repetitions
    
    case date
    case activeDuration
    case pauseDuration
    case pace
    case startTime
    case endTime
    
    case averageSpeed
    case topSpeed
    
    case energy
    case energyPerMinute
    
    // TODO: add chaching (uuid_lasteditdate_metric)
    public func value(for workout: Workout) -> ValueRepresentation? {
        switch self {
        case .distance:
            .longDistanceMeasurement(.init(value: workout.distance, unit: .meters))
        case .ascend:
            if let ascend = elevation(for: workout)?.ascend {
                .shortDistanceMeasurement(.init(value: Double(ascend), unit: .meters))
            } else {
                nil
            }
        case .descend:
            if let descend = elevation(for: workout)?.descend {
                .shortDistanceMeasurement(.init(value: Double(descend), unit: .meters))
            } else {
                nil
            }
        case .repetitions:
            if let repetitions = workout.repetitions {
                .integerValue(repetitions)
            } else {
                nil
            }
        case .date:
            .day(workout.startDate)
        case .activeDuration:
            if let duration = activeDuration(for: workout) {
                .hourDuration(duration)
            } else {
                nil
            }
        case .pauseDuration:
            .hourDuration(pauseDuration(for: workout))
        case .pace:
            .paceMeasurement(averageSpeed(for: workout))
        case .startTime:
            .timeOfDay(workout.startDate)
        case .endTime:
            if let endDate = workout.endDate {
                .timeOfDay(endDate)
            } else {
                nil
            }
        case .averageSpeed:
            .speedMeasurement(averageSpeed(for: workout))
        case .topSpeed:
            if let topSpeed = topSpeed(for: workout) {
                .speedMeasurement(topSpeed)
            } else {
                nil
            }
        case .energy:
            if let energy = workout.energy {
                .energyMeasurement(.init(value: energy, unit: .joules))
            } else {
                nil
            }
        case .energyPerMinute:
            if let energyPerMinute = energyPerMinute(for: workout) {
                .energyMeasurement(energyPerMinute)
            } else {
                nil
            }
        }
    }
    
    private func pauseDuration(for workout: Workout) -> TimeInterval {
        workout.pauses.reduce(TimeInterval(), { $0 + $1.duration })
    }
    
    private func activeDuration(for workout: Workout) -> TimeInterval? {
        guard let endDate = workout.endDate else { return nil }
        return workout.startDate.distance(to: endDate) - pauseDuration(for: workout)
    }
    
    private func averageSpeed(for workout: Workout) -> Measurement<UnitSpeed> {
        guard let activeDuration = activeDuration(for: workout), activeDuration > 0, workout.distance > 0
        else { return .init(value: 0, unit: .metersPerSecond) }
        return .init(value: workout.distance / activeDuration, unit: .metersPerSecond)
    }
    
    private func topSpeed(for workout: Workout) -> Measurement<UnitSpeed>? {
        var topSpeed: Float?
        for routeSample in workout.route where routeSample.speed > 0 {
            guard topSpeed == nil || routeSample.speed > topSpeed ?? 0 else { continue }
            topSpeed = routeSample.speed
        }
        guard let topSpeed else { return nil }
        return .init(value: Double(topSpeed), unit: .metersPerSecond)
    }
    
    private func energyPerMinute(for workout: Workout) -> Measurement<UnitEnergy>? {
        guard let energy = workout.energy, let activeDuration = activeDuration(for: workout) else { return nil }
        let minutes = UnitDuration.minutes.converter.value(fromBaseUnitValue: activeDuration)
        return .init(value: energy / minutes, unit: .joules)
    }
    
    private func elevation(for workout: Workout) -> Calculation.ElevationTouple? {
        let altitudes = workout.route.compactMap({ $0.altitude > 0 ? $0.altitude : nil })
        return Calculation.calculateElevationData(from: altitudes)
    }
    
    public enum ValueRepresentation {
        /// Represents long distances such as the distance covered during a workout.
        case longDistanceMeasurement(Measurement<UnitLength>)
        /// Represents short distances such as altitude changes.
        case shortDistanceMeasurement(Measurement<UnitLength>)
        /// Represents an integer value such as for repetitions.
        case integerValue(Int)
        /// Represents a date that should be formatted as a date.
        case day(Date)
        /// Represents a date that should be formatted as a time of day.
        case timeOfDay(Date)
        /// Represents a duration that should be formatted as minutes and seconds.
        case minuteDuration(TimeInterval)
        /// Represents a duration that is most likely under one day and should be formatted as hours, minutes and seconds.
        case hourDuration(TimeInterval)
        /// Represents a speed that should be formatted as conventional.
        case speedMeasurement(Measurement<UnitSpeed>)
        /// Represents a speed that should be formatted as a pace (duration / major distance unit)
        case paceMeasurement(Measurement<UnitSpeed>)
        /// Represents energy burned during the workout.
        case energyMeasurement(Measurement<UnitEnergy>)
    }
}
