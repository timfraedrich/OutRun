//
//  WorkoutHeartRateDataSample.swift
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

typealias WorkoutHeartRateDataSample = OutRunV4.WorkoutHeartRateDataSample

extension WorkoutHeartRateDataSample: CustomStringConvertible, WorkoutSeriesDataSampleType {
    
    var description: String {
        
        var desc = "WorkoutHeartRateDataSample("
        
        if let uuid = uuid {
            desc += "uuid: \(uuid), "
        }
        
        return desc + "heartRate: \(heartRate), timestamp: \(timestamp)"
    }
    
}

// MARK: - ORWorkoutHeartRateDataSampleInterface

extension WorkoutHeartRateDataSample: ORWorkoutHeartRateDataSampleInterface {
    
    var uuid: UUID? { threadSafeSyncReturn { self._uuid.value } }
    var heartRate: Int { threadSafeSyncReturn { self._heartRate.value } }
    var timestamp: Date { threadSafeSyncReturn { self._timestamp.value } }
    var workout: ORWorkoutInterface? { self._workout.value }
    
}

// MARK: - TempValueConvertible

extension WorkoutHeartRateDataSample: TempValueConvertible {
    
    var asTemp: TempWorkoutHeartRateDataSample {
        TempWorkoutHeartRateDataSample(
            uuid: uuid,
            heartRate: heartRate,
            timestamp: timestamp
        )
    }
    
}
