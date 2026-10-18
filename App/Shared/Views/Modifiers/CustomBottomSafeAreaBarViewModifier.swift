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

struct CustomBottomSafeAreaBarViewModifier<SafeAreaBarContent: View>: ViewModifier {

    private let ignoredSafeAreaRegions: SafeAreaRegions
    private let safeAreaBarContent: () -> SafeAreaBarContent

    func body(content: Content) -> some View {
        let horizontalPadding: Spacing = if #available(iOS 26, *) { .extraLarge } else { .large }
        let topPadding: Spacing = if #available(iOS 27, *) { .regular } else if #available(iOS 26, *) { .extraLarge } else { .regular }
        let bottomPadding: Spacing = if #available(iOS 26, *) { .extraLarge } else { .regular }
        content.compatibleSafeAreaBar(edge: .bottom) {
            safeAreaBarContent()
                .padding(.horizontal, horizontalPadding)
                .padding(.top, topPadding)
                .padding(.bottom, bottomPadding)
                .background {
                    if #available(iOS 27.0, *) {
                        BackgroundBlackoutGradient(startPoint: .top, endPoint: .center)
                    }
                }
        }
        .ignoresBottomSafeAreaOnIOS26OrLater(regions: ignoredSafeAreaRegions)
    }

    init(ignoredSafeAreaRegions: SafeAreaRegions, @ViewBuilder safeAreaBarContent: @escaping () -> SafeAreaBarContent) {
        self.ignoredSafeAreaRegions = ignoredSafeAreaRegions
        self.safeAreaBarContent = safeAreaBarContent
    }
}

extension View {

    /// - note: ignoredSafeAreaRegions is only respected for iOS 26 and later.
    @ViewBuilder
    func customBottomSafeAreaBar<Content: View>(
        ignoredSafeAreaRegions: SafeAreaRegions = .container,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(CustomBottomSafeAreaBarViewModifier(ignoredSafeAreaRegions: ignoredSafeAreaRegions, safeAreaBarContent: content))
    }
}
