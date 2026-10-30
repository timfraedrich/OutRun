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

#if !RELEASE
extension UserPreferences {

    /// The number of natively recorded workouts required before completing a workout makes the donation prompt due.
    static let donationPromptWorkoutThreshold = 5

    /// Indicates whether a workout was completed after reaching ``donationPromptWorkoutThreshold``. Only persisted until the prompt is
    /// dismissed.
    private(set) var donationPromptDue: Bool {
        get { value(for: UserPreferenceKeys.donationPromptDue) }
        set { setValue(newValue ? true : nil, for: UserPreferenceKeys.donationPromptDue) }
    }

    private(set) var donationPromptDismissed: Bool {
        get { value(for: UserPreferenceKeys.donationPromptDismissed) }
        set { setValue(newValue ? true : nil, for: UserPreferenceKeys.donationPromptDismissed) }
    }

    func registerCompletedWorkout(nativeWorkoutCount: Int) {
        guard !donationPromptDue, !donationPromptDismissed, nativeWorkoutCount >= Self.donationPromptWorkoutThreshold else { return }
        donationPromptDue = true
    }

    func dismissDonationPrompt() {
        donationPromptDue = false
        donationPromptDismissed = true
    }
}
#endif
