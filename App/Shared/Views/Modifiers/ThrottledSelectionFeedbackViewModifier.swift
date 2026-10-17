import SwiftUI

private struct ThrottledSelectionFeedbackViewModifier<Trigger: Equatable>: ViewModifier {
    
    @State private var lastFeedbackDate: Date = .distantPast
    @State private var feedbackCount = 0
    let trigger: Trigger?
    let minimumInterval: TimeInterval
    
    func body(content: Content) -> some View {
        content
            .sensoryFeedback(.selection, trigger: feedbackCount)
            .onChange(of: trigger) { _, newValue in
                let now = Date.now
                guard newValue != nil, lastFeedbackDate.distance(to: now) >= minimumInterval else { return }
                lastFeedbackDate = now
                feedbackCount += 1
            }
    }
}

extension View {
    
    /// Plays selection feedback whenever the trigger changes to a non-nil value, skipping changes that follow the previous feedback
    /// within the minimum interval to stay below the rate the Taptic Engine supports.
    func throttledSelectionFeedback<Trigger: Equatable>(trigger: Trigger?, minimumInterval: TimeInterval = 0.1) -> some View {
        modifier(ThrottledSelectionFeedbackViewModifier(trigger: trigger, minimumInterval: minimumInterval))
    }
}
