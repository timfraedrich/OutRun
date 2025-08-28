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
}
