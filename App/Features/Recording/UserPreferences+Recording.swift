//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import OutRunCore

extension UserPreferences {

    /// Indicates whether the detail view of a workout is presented right after its recording ended instead of a notice offering to open it.
    /// The default value is `true`.
    var openWorkoutAfterRecording: Bool {
        get { value(for: UserPreferenceKeys.openWorkoutAfterRecording, defaultValue: true) }
        set { setValue(newValue, for: UserPreferenceKeys.openWorkoutAfterRecording) }
    }
}
