import SwiftUI

/// A prompt shown on the main scene asking the user to support the app.
///
/// Prompts are shown one after another in the order of ``allCases``. Each prompt becomes due once a natively recorded workout was added
/// after the previous prompt was dismissed, or, for the first prompt, after the baseline was established.
enum SupportPrompt: CaseIterable, Identifiable {
    
    case rating
    
    var id: String {
        switch self {
        case .rating: "rating"
        }
    }
    
    var title: LocalizedStringKey {
        switch self {
        case .rating: "support_prompt_rating_title"
        }
    }
    
    var message: LocalizedStringKey {
        switch self {
        case .rating: "support_prompt_rating_message"
        }
    }
    
    var systemImage: String {
        switch self {
        case .rating: "star.fill"
        }
    }
    
    var actionTitle: LocalizedStringKey {
        switch self {
        case .rating: "support_prompt_rating_action"
        }
    }
    
    /// Returns the first prompt that has not been dismissed yet, if a natively recorded workout was added since the preceding prompt was
    /// dismissed.
    static func pending(nativeWorkoutCount: Int, baseline: Int, dismissals: [String: Int]) -> SupportPrompt? {
        var threshold = baseline
        for prompt in allCases {
            guard let dismissalCount = dismissals[prompt.id] else {
                return nativeWorkoutCount > threshold ? prompt : nil
            }
            threshold = dismissalCount
        }
        return nil
    }
}
