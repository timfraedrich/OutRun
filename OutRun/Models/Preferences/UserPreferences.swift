//
//  UserPreferences.swift
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

import UIKit

struct UserPreferences {
    
    /// saves if app is set up
    static let isSetUp = UserPreference.Required<Bool>(key: "isSetUp", defaultValue: false)
    
    /// saves the users name
    static let name = UserPreference.Optional<String>(key: "name")
    /// saves the users weight in kg
    static let weight = UserPreference.Optional<Double>(key: "weight")
    
    static let standardWorkoutType = UserPreference.Required<Int>(key: "standardWorkoutType", defaultValue: 0)
    static let shouldShowMap = UserPreference.Required<Bool>(key: "shouldShowMap", defaultValue: true)
    static let gpsAccuracy = UserPreference.Optional<Double>(key: "gpsAccuracy", initialValue: nil)
    static let usePaceForSpeedDisplay = UserPreference.Required<Bool>(key: "usesPaceForRecording", defaultValue: true)
    static let displayRollingSpeed = UserPreference.Required<Bool>(key: "makeSpeedDisplayRolling", defaultValue: true)
    
    static let synchronizeWorkoutsWithAppleHealth = UserPreference.Required<Bool>(key: "savesToAppleHealth", defaultValue: false)
    static let synchronizeWeightWithAppleHealth = UserPreference.Required<Bool>(key: "synchronizeWeightWithAppleHealth", defaultValue: false)
    static let automaticallyImportNewHealthWorkouts = UserPreference.Required<Bool>(key: "automaticallyImportNewHealthWorkouts", defaultValue: false)
    
    static let distanceMeasurementType = MeasurementUserPreference<UnitLength>(key: "distanceMeasurementType", possibleValues: [.kilometers, .miles])
    static let altitudeMeasurementType = MeasurementUserPreference<UnitLength>(key: "altitudeMeasurementType", possibleValues: [.meters, .feet], bigUnits: false)
    static let speedMeasurementType = MeasurementUserPreference<UnitSpeed>(key: "speedMeasurementType", possibleValues: [.kilometersPerHour, .milesPerHour])
    static let energyMeasurementType = MeasurementUserPreference<UnitEnergy>(key: "energyMeasurementType", possibleValues: [.kilojoules, .kilocalories])
    static let weightMeasurementType = MeasurementUserPreference<UnitMass>(key: "weightMeasurementType", possibleValues: [.kilograms, .pounds])
    
    static func reset() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }
    
}
