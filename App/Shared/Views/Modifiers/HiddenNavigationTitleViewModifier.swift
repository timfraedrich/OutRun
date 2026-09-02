import SwiftUI

private struct HiddenNavigationTitleViewModifier: ViewModifier {
    
    let titleKey: LocalizedStringKey
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(titleKey)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    Color.clear
                }
            }
    }
}

extension View {
    
    @ViewBuilder
    func hiddenNavigationTitle(_ titleKey: LocalizedStringKey) -> some View {
        modifier(HiddenNavigationTitleViewModifier(titleKey: titleKey))
    }
}
