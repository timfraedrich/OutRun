//
//  [FILENAME]
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

/// A static class to standardise the computation of data properties across the app
class Computation {
    
    /**
     Computes the elevation changes (ascending and descending) from altitudes of a workouts route
     - parameter altitudes: the provided elevations from the route data samples
     - returns: the calculated ascending and descending altitude in a touple of two values
     */
    static func computeElevationData(from altitudes: [Double]) -> (ascending: Double, descending:  Double) {
        
        var tempAscending: Double = 0
        var tempDescending: Double = 0
        
        let threshold = 1.5
        
        var lastConsideredRoundedAltitude: Double?
        
        for (index, value) in altitudes.enumerated() {
            
            var tempSum = value
            var tempCount: Double = 1
            
            for i in (index - 5)...(index + 5) where altitudes.indices.contains(i) {
                if let altitude = altitudes.safeValue(for: i) {
                    tempSum += altitude
                    tempCount += 1
                }
            }
            let rounded = (tempSum / tempCount)
            
            guard let lastRounded = lastConsideredRoundedAltitude else {
                lastConsideredRoundedAltitude = rounded
                continue
            }
            
            let difference = rounded - lastRounded
            
            if abs(difference) >= threshold {
                if difference > 0 {
                    tempAscending += difference
                } else if difference < 0 {
                    tempDescending += abs(difference)
                }
                lastConsideredRoundedAltitude = rounded
            }
        }
        
        return (tempAscending, tempDescending)
        
    }
    
    
}
