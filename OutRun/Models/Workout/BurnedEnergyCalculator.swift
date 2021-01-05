//
//  BurnedEnergyCalculator.swift
//
//  OutRun
//  Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

class BurnedEnergyCalculator {
    
    
    static func calculateBurnedCalories(for type: Workout.WorkoutType, distance: Double, weight: Double) -> NSMeasurement {
        
        /// calories == MET ( speed ( kilometers / hours ) * METSpeedMultiplier ) * weight * hours
        ///          == kilometers / hours * METSpeedMultiplier * weight * hours
        ///          == kilometers * METSpeedMultiplier * weight
        
        let kilometers = distance / 1000
        let burnedCal = kilometers * type.METSpeedMultiplier * weight
        
        let measurement = NSMeasurement(doubleValue: burnedCal, unit: UnitEnergy.kilocalories)
        return measurement
    }

    static func calculeWeightBeforeWorkout(for type: Workout.WorkoutType, distance: Double, burnedCal: Double) -> Double {

        /// burnedCal = kilometers * type.METSpeedMultiplier * weight
        /// (kilometers * type.METSpeedMultiplier)weight = burnedCal
        /// weight = burnedCal/(kilometers * type.METSpeedMultiplier)

        let kilometers = distance / 1000
        let weight = burnedCal / (kilometers * type.METSpeedMultiplier)
        return weight
    }
}
