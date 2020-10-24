//
//  WorkoutRouteDataSample+ORWorkoutRouteDataSampleInterface.swift
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

// Note: For documentation see ORWorkoutRouteDataSampleInterface.
extension WorkoutRouteDataSample: ORWorkoutRouteDataSampleInterface {
    
    var uuid: UUID? {
        threadSafeSyncReturn { () -> UUID? in
            return self._uuid.value
        }
    }
    
    var timestamp: Date {
        threadSafeSyncReturn { () -> Date in
            return self._timestamp.value
        }
    }
    
    var latitude: Double {
        threadSafeSyncReturn { () -> Double in
            return self._latitude.value
        }
    }
    
    var longitude: Double {
        threadSafeSyncReturn { () -> Double in
            return self._longitude.value
        }
    }
    
    var altitude: Double {
        threadSafeSyncReturn { () -> Double in
            return self._altitude.value
        }
    }
    
    var horizontalAccuracy: Double {
        threadSafeSyncReturn { () -> Double in
            return self._horizontalAccuracy.value
        }
    }
    
    var verticalAccuracy: Double {
        threadSafeSyncReturn { () -> Double in
            return self._verticalAccuracy.value
        }
    }
    
    var speed: Double {
        threadSafeSyncReturn { () -> Double in
            return self._speed.value
        }
    }
    
    var direction: Double {
        threadSafeSyncReturn { () -> Double in
            return self._direction.value
        }
    }
    
    var workout: ORWorkoutInterface? {
        threadSafeSyncReturn { () -> ORWorkoutInterface? in
            return self._workout.value
        }
    }
    
}
