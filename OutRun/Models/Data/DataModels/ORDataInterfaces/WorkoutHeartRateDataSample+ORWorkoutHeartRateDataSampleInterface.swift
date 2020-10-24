//
//  WorkoutHeartRateDataSample+ORWorkoutHeartRateDataSampleInterface.swift
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

// Note: For documentation see ORWorkoutHeartRateDataSampleInterface.
extension WorkoutHeartRateDataSample: ORWorkoutHeartRateDataSampleInterface {
    
    var uuid: UUID? {
        threadSafeSyncReturn { () -> UUID? in
            return self._uuid.value
        }
    }
    
    var heartRate: Int {
        threadSafeSyncReturn { () -> Int in
            return self._heartRate.value
        }
    }
    
    var timestamp: Date {
        threadSafeSyncReturn { () -> Date in
            return self._timestamp.value
        }
    }
    
    var workout: ORWorkoutInterface? {
        return self._workout.value
    }
    
}
