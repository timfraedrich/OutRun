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

// Note: For documentation see OREventInterface.
extension Event: OREventInterface {
    
    var uuid: UUID? {
        threadSafeSyncReturn { () -> UUID? in
            return self._uuid.value
        }
    }
    
    var title: String {
        threadSafeSyncReturn { () -> String in
            return self._title.value
        }
    }
    
    var comment: String? {
        threadSafeSyncReturn { () -> String? in
            return self._comment.value
        }
    }
    
    var startDate: Date? {
        threadSafeSyncReturn { () -> Date? in
            return self._startDate.value
        }
    }
    
    var endDate: Date? {
        threadSafeSyncReturn { () -> Date? in
            return self._endDate.value
        }
    }
    
    var workouts: [ORWorkoutInterface] {
        return self._workouts.value
    }
    
}
