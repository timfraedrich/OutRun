import SwiftUI

struct NavigationLinkButton<Label: View>: View {
    
    let action: () -> Void
    let label: () -> Label
    
    var body: some View {
        Button(action: action) {
            NavigationLink(destination: EmptyView.init, label: label)
        }
    }
    
    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }
    
    init(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) where Label == Text {
        self.init(action: action) {
            Text(titleKey)
        }
    }
}
