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
