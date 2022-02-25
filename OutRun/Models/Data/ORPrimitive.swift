//
//  ORPrimitive.swift
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

/// A structure used to represent any database object just by it's uuid; accessing any different variable will result in a fatal error.
class ORPrimitive<Reference>: ORDataInterface, ORSampleInterface {
    
    var uuid: UUID? { _uuid }
    
    let _uuid: UUID
    
    init(uuid: UUID) {
        self._uuid = uuid
    }
    
}

extension ORPrimitive: ORWorkoutInterface where Reference == Workout {}
extension ORPrimitive: ORWorkoutPauseInterface where Reference == WorkoutPause {
    // this somehow needs to be declared here again (ORSampleInterface inheritance somehow broke it)
    var workout: ORWorkoutInterface? { throwOnAccess() }
}
extension ORPrimitive: ORWorkoutEventInterface where Reference == WorkoutEvent {}
extension ORPrimitive: ORWorkoutRouteDataSampleInterface where Reference == WorkoutRouteDataSample {}
extension ORPrimitive: ORWorkoutHeartRateDataSampleInterface where Reference == WorkoutHeartRateDataSample {}
extension ORPrimitive: OREventInterface where Reference == Event {}
