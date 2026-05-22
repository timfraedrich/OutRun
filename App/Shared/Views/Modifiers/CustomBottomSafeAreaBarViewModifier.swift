import SwiftUI

struct CustomBottomSafeAreaBarViewModifier<SafeAreaBarContent: View>: ViewModifier {
    
    private let safeAreaBarContent: () -> SafeAreaBarContent
    
    func body(content: Content) -> some View {
        let horizontalPadding: Spacing = if #available(iOS 26, *) { .extraLarge } else { .large }
        let verticalPadding: Spacing = if #available(iOS 26, *) { .extraLarge } else { .regular }
        content.compatibleSafeAreaBar(edge: .bottom) {
            safeAreaBarContent()
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
        }
        .ignoresBottomSafeAreaOnIOS26OrLater()
    }
    
    init(@ViewBuilder safeAreaBarContent: @escaping () -> SafeAreaBarContent) {
        self.safeAreaBarContent = safeAreaBarContent
    }
}

extension View {
    
    @ViewBuilder
    func customBottomSafeAreaBar<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        modifier(CustomBottomSafeAreaBarViewModifier(safeAreaBarContent: content))
    }
}
