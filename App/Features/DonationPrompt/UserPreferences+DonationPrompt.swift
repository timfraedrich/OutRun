import Foundation
import OutRunCore

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
