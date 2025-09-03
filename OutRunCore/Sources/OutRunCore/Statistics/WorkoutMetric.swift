import Foundation

public enum WorkoutMetric: CustomStringConvertible {
    
    case type
    
    case distance
    case ascent
    case descent
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
    
    public var description: String {
        switch self {
        case .type: R.string.localizable.workout_metric_type()
        case .distance: R.string.localizable.workout_metric_distance()
        case .ascent: R.string.localizable.workout_metric_ascent()
        case .descent: R.string.localizable.workout_metric_descent()
        case .repetitions: R.string.localizable.workout_metric_repetitions()
        case .date: R.string.localizable.workout_metric_date()
        case .activeDuration: R.string.localizable.workout_metric_active_duration()
        case .pauseDuration: R.string.localizable.workout_metric_pause_duration()
        case .pace: R.string.localizable.workout_metric_pace()
        case .startTime: R.string.localizable.workout_metric_start_time()
        case .endTime: R.string.localizable.workout_metric_end_time()
        case .averageSpeed: R.string.localizable.workout_metric_average_speed()
        case .topSpeed: R.string.localizable.workout_metric_top_speed()
        case .energy: R.string.localizable.workout_metric_energy()
        case .energyPerMinute: R.string.localizable.workout_metric_energy_per_minute()
        }
    }
    
    // TODO: add caching (uuid_lasteditdate_metric)
    public func value(for workout: any WorkoutProtocol) -> ValueRepresentation? {
        switch self {
        case .type:
            .type(workout.type)
        case .distance:
            .longDistanceMeasurement(.init(value: workout.distance, unit: .meters))
        case .ascent:
            if let ascent = elevation(for: workout)?.ascent {
                .shortDistanceMeasurement(.init(value: Double(ascent), unit: .meters))
            } else {
                nil
            }
        case .descent:
            if let descent = elevation(for: workout)?.descent {
                .shortDistanceMeasurement(.init(value: Double(descent), unit: .meters))
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
                .duration(duration)
            } else {
                nil
            }
        case .pauseDuration:
            .duration(pauseDuration(for: workout))
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
    
    private func pauseDuration(for workout: any WorkoutProtocol) -> TimeInterval {
        workout.pauses.reduce(TimeInterval(), { $0 + $1.duration })
    }
    
    private func activeDuration(for workout: any WorkoutProtocol) -> TimeInterval? {
        guard let endDate = workout.endDate else { return nil }
        return workout.startDate.distance(to: endDate) - pauseDuration(for: workout)
    }
    
    private func averageSpeed(for workout: any WorkoutProtocol) -> Measurement<UnitSpeed> {
        guard let activeDuration = activeDuration(for: workout), activeDuration > 0, workout.distance > 0
        else { return .init(value: 0, unit: .metersPerSecond) }
        return .init(value: workout.distance / activeDuration, unit: .metersPerSecond)
    }
    
    private func topSpeed(for workout: any WorkoutProtocol) -> Measurement<UnitSpeed>? {
        var topSpeed: Float?
        for routeSample in workout.route where routeSample.speed > 0 {
            guard topSpeed == nil || routeSample.speed > topSpeed ?? 0 else { continue }
            topSpeed = routeSample.speed
        }
        guard let topSpeed else { return nil }
        return .init(value: Double(topSpeed), unit: .metersPerSecond)
    }
    
    private func energyPerMinute(for workout: any WorkoutProtocol) -> Measurement<UnitEnergy>? {
        guard let energy = workout.energy, let activeDuration = activeDuration(for: workout) else { return nil }
        let minutes = UnitDuration.minutes.converter.value(fromBaseUnitValue: activeDuration)
        return .init(value: energy / minutes, unit: .joules)
    }
    
    private func elevation(for workout: any WorkoutProtocol) -> Calculation.ElevationTouple? {
        let altitudes = workout.route.compactMap({ $0.altitude > 0 ? $0.altitude : nil })
        return Calculation.calculateElevationData(from: altitudes)
    }
    
    public enum ValueRepresentation {
        /// Represents the workout type
        case type(WorkoutType)
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
        /// Represents a duration that is most likely under one day and should be formatted as hours, minutes and seconds.
        case duration(TimeInterval)
        /// Represents a speed that should be formatted as conventional.
        case speedMeasurement(Measurement<UnitSpeed>)
        /// Represents a speed that should be formatted as a pace (duration / major distance unit)
        case paceMeasurement(Measurement<UnitSpeed>)
        /// Represents energy burned during the workout.
        case energyMeasurement(Measurement<UnitEnergy>)
    }
}
