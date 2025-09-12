import Foundation

enum Calculation {
    
    // TODO: Use more advanced energy calculation.
    static func calculateBurnedEnergy(distance: Double, workoutType: WorkoutType) -> Double {
        // TODO: Use actual user weight.
        let weight: Double = 70
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
            for j in (i - 5)...(i + 5) where i >= 0 && i < altitudes.count {
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
}
