import Foundation
import OutRunCore

extension UserPreferences {

    /// The number of natively recorded workouts required before the donation prompt is shown.
    static let donationPromptWorkoutThreshold = 5

    var donationPromptDismissed: Bool {
        get { value(for: UserPreferenceKeys.donationPromptDismissed) }
        set { setValue(newValue, for: UserPreferenceKeys.donationPromptDismissed) }
    }

    func shouldShowDonationPrompt(nativeWorkoutCount: Int) -> Bool {
        !donationPromptDismissed && nativeWorkoutCount >= Self.donationPromptWorkoutThreshold
    }
}
