import Foundation
import OutRunCore

extension UserPreferences {

    /// The number of natively recorded workouts at the time support prompts were first evaluated. Existing users therefore only see the first
    /// prompt after recording another workout.
    var supportPromptBaseline: Int? {
        get { value(for: UserPreferenceKeys.supportPromptBaseline) }
        set { setValue(newValue, for: UserPreferenceKeys.supportPromptBaseline) }
    }

    /// The number of natively recorded workouts at the time each prompt was dismissed, keyed by ``SupportPrompt/id``.
    var supportPromptDismissals: [String: Int] {
        get { value(for: UserPreferenceKeys.supportPromptDismissals) ?? [:] }
        set { setValue(newValue, for: UserPreferenceKeys.supportPromptDismissals) }
    }

    func establishSupportPromptBaselineIfNeeded(nativeWorkoutCount: Int) {
        guard supportPromptBaseline == nil else { return }
        supportPromptBaseline = nativeWorkoutCount
    }

    func pendingSupportPrompt(nativeWorkoutCount: Int) -> SupportPrompt? {
        guard let supportPromptBaseline else { return nil }
        return SupportPrompt.pending(
            nativeWorkoutCount: nativeWorkoutCount,
            baseline: supportPromptBaseline,
            dismissals: supportPromptDismissals
        )
    }

    func dismissSupportPrompt(_ prompt: SupportPrompt, nativeWorkoutCount: Int) {
        supportPromptDismissals[prompt.id] = nativeWorkoutCount
    }
}
