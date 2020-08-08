//
//  WorkoutBuilderDelegate.swift
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
import CoreLocation

protocol WorkoutBuilderDelegate: class {
    
    func didUpdate(distanceMeasurement: NSMeasurement)
    func didUpdate(durationMeasurement: NSMeasurement)
    func didUpdate(speedMeasurement: NSMeasurement, rolling: Bool)
    func didUpdate(energyMeasurement: NSMeasurement)
    func didUpdate(paceMeasurement: RelativeMeasurement, rolling: Bool)
    func didUpdate(status: WorkoutBuilder.Status)
    func didUpdate(routeData: [CLLocation])
    func didUpdate(currentLocation location: CLLocation, force: Bool)
    func didUpdate(uiUpdatesSuspended: Bool)
    func informOfInsufficientLocationPermission()
    
}

extension WorkoutBuilderDelegate {
    
    func didUpdate(distanceMeasurement: NSMeasurement) {}
    func didUpdate(durationMeasurement: NSMeasurement) {}
    func didUpdate(speedMeasurement: NSMeasurement, rolling: Bool) {}
    func didUpdate(energyMeasurement: NSMeasurement) {}
    func didUpdate(paceMeasurement: RelativeMeasurement, rolling: Bool) {}
    func didUpdate(status: WorkoutBuilder.Status) {}
    func didUpdate(routeData: [CLLocation]) {}
    func didUpdate(currentLocation: CLLocation, force: Bool) {}
    func didUpdate(uiUpdatesSuspended: Bool) {}
    func informOfInsufficientLocationPermission() {}
    
    func resetAll() {
        self.didUpdate(distanceMeasurement: NSMeasurement(doubleValue: 0, unit: UnitLength.meters))
        self.didUpdate(durationMeasurement: NSMeasurement(doubleValue: 0, unit: UnitDuration.seconds))
        self.didUpdate(speedMeasurement: NSMeasurement(doubleValue: 0, unit: UnitSpeed.metersPerSecond), rolling: UserPreferences.displayRollingSpeed.value)
        self.didUpdate(energyMeasurement: NSMeasurement(doubleValue: 0, unit: UnitEnergy.kilocalories))
        self.didUpdate(paceMeasurement: RelativeMeasurement(value: 0, primaryUnit: UnitDuration.minutes, dividingUnit: UserPreferences.distanceMeasurementType.safeValue), rolling: UserPreferences.displayRollingSpeed.value)
    }
    
}
