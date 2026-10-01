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
