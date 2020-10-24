//
//  Workout+ORWorkoutInterface.swift
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

// Note: For documentation see ORWorkoutInterface.
extension Workout: ORWorkoutInterface {
    
    var uuid: UUID? {
        threadSafeSyncReturn { () -> UUID? in
            return self._uuid.value
        }
    }
    
    var workoutType: Workout.WorkoutType {
        threadSafeSyncReturn { () -> Workout.WorkoutType in
            return self._workoutType.value
        }
    }
    
    var distance: Double {
        threadSafeSyncReturn { () -> Double in
            return self._distance.value
        }
    }
    
    var steps: Int? {
        threadSafeSyncReturn { () -> Int? in
            return self._steps.value
        }
    }
    
    var startDate: Date {
        threadSafeSyncReturn { () -> Date in
            return self._startDate.value
        }
    }
    
    var endDate: Date {
        threadSafeSyncReturn { () -> Date in
            return self._endDate.value
        }
    }
    
    var burnedEnergy: Double? {
        threadSafeSyncReturn { () -> Double? in
            return self._burnedEnergy.value
        }
    }
    
    var isRace: Bool {
        threadSafeSyncReturn { () -> Bool in
            return self._isRace.value
        }
    }
    
    var comment: String? {
        threadSafeSyncReturn { () -> String? in
            return self._comment.value
        }
    }
    
    var isUserModified: Bool {
        threadSafeSyncReturn { () -> Bool in
            return self._isUserModified.value
        }
    }
    
    var healthKitUUID: UUID? {
        threadSafeSyncReturn { () -> UUID? in
            return self._healthKitUUID.value
        }
    }
    
    var ascend: Double {
        threadSafeSyncReturn { () -> Double in
            return self._ascend.value
        }
    }
    
    var descend: Double {
        threadSafeSyncReturn { () -> Double in
            return self._descend.value
        }
    }
    
    var activeDuration: Double {
        threadSafeSyncReturn { () -> Double in
            return self._activeDuration.value
        }
    }
    
    var pauseDuration: Double {
        threadSafeSyncReturn { () -> Double in
            return self._pauseDuration.value
        }
    }
    
    var dayIdentifier: String {
        threadSafeSyncReturn { () -> String in
            return self._dayIdentifier.value
        }
    }
    
    var heartRates: [ORWorkoutHeartRateDataSampleInterface] {
        return self._heartRates.value
    }
    
    var routeData: [ORWorkoutRouteDataSampleInterface] {
        return self._routeData.value
    }
    
    var pauses: [ORWorkoutPauseInterface] {
        return self._pauses.value
    }
    
    var workoutEvents: [ORWorkoutEventInterface] {
        return self._workoutEvents.value
    }
    
    var events: [OREventInterface] {
        return self._events.value
    }
    
}
