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
    case averageHeartRate
    case maximumHeartRate
    case averageSpeed
    case topSpeed
    case energy
    case energyPerMinute
    
    public var description: String {
        switch self {
        case .type: .init(localized: "workout_metric_type", bundle: .module)
        case .distance: .init(localized: "workout_metric_distance", bundle: .module)
        case .ascent: .init(localized: "workout_metric_ascent", bundle: .module)
        case .descent: .init(localized: "workout_metric_descent", bundle: .module)
        case .repetitions: .init(localized: "workout_metric_repetitions", bundle: .module)
        case .date: .init(localized: "workout_metric_date", bundle: .module)
        case .activeDuration: .init(localized: "workout_metric_active_duration", bundle: .module)
        case .pauseDuration: .init(localized: "workout_metric_pause_duration", bundle: .module)
        case .pace: .init(localized: "workout_metric_pace", bundle: .module)
        case .startTime: .init(localized: "workout_metric_start_time", bundle: .module)
        case .endTime: .init(localized: "workout_metric_end_time", bundle: .module)
        case .averageHeartRate: .init(localized: "workout_metric_average_heart_rate", bundle: .module)
        case .maximumHeartRate: .init(localized: "workout_metric_maximum_heart_rate", bundle: .module)
        case .averageSpeed: .init(localized: "workout_metric_average_speed", bundle: .module)
        case .topSpeed: .init(localized: "workout_metric_top_speed", bundle: .module)
        case .energy: .init(localized: "workout_metric_energy", bundle: .module)
        case .energyPerMinute: .init(localized: "workout_metric_energy_per_minute", bundle: .module)
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
        case .averageHeartRate:
            if let averageHeartRate = averageHeartRate(for: workout) {
                .heartRate(averageHeartRate)
            } else {
                nil
            }
        case .maximumHeartRate:
            if let maximumHeartRate = maximumHeartRate(for: workout) {
                .heartRate(maximumHeartRate)
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
    
    private func averageHeartRate(for workout: any WorkoutProtocol) -> UInt8? {
        Calculation.calculateAverageHeartRate(heartRates: workout.heartRates)
    }
    
    private func maximumHeartRate(for workout: any WorkoutProtocol) -> UInt8? {
        Calculation.calculateMaximumHeartRate(heartRates: workout.heartRates)
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
        /// Represents a heart rate.
        case heartRate(UInt8)
    }
}
