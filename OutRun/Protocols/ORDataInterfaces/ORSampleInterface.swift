//
//  ORSampleInterface
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

/// A protocol to unify common datapoints of the samples of a workout.
public protocol ORSampleInterface: ORDataInterface {
    
    /// The `Date` the sample was recorded.
    var timestamp: Date { get }
    /// A reference to the `Workout` this sample is associated with.
    var workout: ORWorkoutInterface? { get }
    
}

extension ORSampleInterface {
    
    var timestamp: Date { throwOnAccess() }
    var workout: ORWorkoutInterface? { throwOnAccess() }
    
}
