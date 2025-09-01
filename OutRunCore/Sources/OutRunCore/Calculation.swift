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
    
    typealias ElevationTouple = (ascend: Float, descend: Float)
    
    /// Computes the elevation changes (ascending and descending) from altitudes of a workouts route
    /// - parameter altitudes: the provided elevations from the route data samples
    /// - returns: Returns the calculated ascending and descending altitude in a touple of two values if the altitudes collection had at
    /// least two values.
    static func calculateElevationData(from altitudes: [Float]) -> ElevationTouple? {
        guard !altitudes.isEmpty, altitudes.count > 1 else { return nil }
        var ascend: Float = 0, descend: Float = 0
        let threshold: Float = 0.5 // a threshold to filter slight variation due to measurment errors
        var lastConsideredRoundedAltitude: Float?
        for (i, value) in altitudes.enumerated() {
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
                ascend += difference
            } else if difference < 0 {
                descend += -difference
            }
            lastConsideredRoundedAltitude = roundedAltitude
        }
        return (ascend, descend)
    }
}
