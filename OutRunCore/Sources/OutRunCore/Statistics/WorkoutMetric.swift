import Foundation

public enum WorkoutMetric: CaseIterable, CustomStringConvertible, Sendable {
    
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
            if let pauseDuration = pauseDuration(for: workout) as Optional, pauseDuration > .zero {
                .duration(pauseDuration)
            } else {
                nil
            }
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
        Calculation.calculatePauseDuration(pauses: workout.pauses)
    }
    
    private func activeDuration(for workout: any WorkoutProtocol) -> TimeInterval? {
        Calculation.calculateActiveDuration(startDate: workout.startDate, endDate: workout.endDate, pauses: workout.pauses)
    }
    
    private func averageSpeed(for workout: any WorkoutProtocol) -> Measurement<UnitSpeed> {
        Calculation.calculateAverageSpeed(
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate ?? .now,
            pauses: workout.pauses
        )
    }
    
    private func topSpeed(for workout: any WorkoutProtocol) -> Measurement<UnitSpeed>? {
        Calculation.calculateTopSpeed(route: workout.route)
    }
    
    private func energyPerMinute(for workout: any WorkoutProtocol) -> Measurement<UnitEnergy>? {
        Calculation.calculateEnergyPerMinute(
            energy: workout.energy,
            startDate: workout.startDate,
            endDate: workout.endDate,
            pauses: workout.pauses
        )
    }
    
    private func elevation(for workout: any WorkoutProtocol) -> Calculation.ElevationTouple? {
        Calculation.calculateElevationData(from: workout.route)
    }
    
    public enum ValueRepresentation: Sendable {
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
        /// Represents a currently increasing duration that is most likely under one day and should be formatted as hours, minutes and
        /// seconds. The duration displayed should account for the offset.
        case increasingDuration(_ since: Date, _ offset: TimeInterval)
        /// Represents a speed that should be formatted as conventional.
        case speedMeasurement(Measurement<UnitSpeed>)
        /// Represents a speed that should be formatted as a pace (duration / major distance unit)
        case paceMeasurement(Measurement<UnitSpeed>)
        /// Represents energy burned during the workout.
        case energyMeasurement(Measurement<UnitEnergy>)
    }
}
