import SwiftUI

/// A prompt shown on the main scene asking the user to support the app.
///
/// Prompts are shown one after another in the order of ``allCases``. Each prompt becomes due once a natively recorded workout was added
/// after the previous prompt was dismissed, or, for the first prompt, after the baseline was established.
enum SupportPrompt: CaseIterable, Identifiable {
    
    case rating
    case donation
    
    var id: String {
        switch self {
        case .rating: "rating"
        case .donation: "donation"
        }
    }
    
    var title: LocalizedStringKey {
        switch self {
        case .rating: "support_prompt_rating_title"
        case .donation: "support_prompt_donation_title"
        }
    }
    
    var message: LocalizedStringKey {
        switch self {
        case .rating: "support_prompt_rating_message"
        case .donation: "support_prompt_donation_message"
        }
    }
    
    var systemImage: String {
        switch self {
        case .rating: "star.fill"
        case .donation: "heart.fill"
        }
    }
    
    var actionTitle: LocalizedStringKey {
        switch self {
        case .rating: "support_prompt_rating_action"
        case .donation: "support_prompt_donation_action"
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
