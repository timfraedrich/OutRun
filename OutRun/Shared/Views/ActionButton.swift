import SwiftUI

struct ActionButton<Label: View>: View {
    
    let maxWidth: CGFloat?
    let action: () -> Void
    let label: () -> Label
    
    var body: some View {
        Button(action: action) {
            label()
                .frame(maxWidth: maxWidth)
                .foregroundStyle(.white)
                .bold()
        }
        .controlSize(.large)
        .buttonStyle(.action)
    }
    
    init(maxWidth: CGFloat? = .infinity, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.maxWidth = maxWidth
        self.action = action
        self.label = label
    }
    
    init(_ localizedString: LocalizedStringKey, maxWidth: CGFloat? = .infinity, action: @escaping () -> Void) where Label == Text {
        self.init(action: action) {
            Text(localizedString)
        }
    }
    
    init(verbatim content: String, maxWidth: CGFloat? = .infinity, action: @escaping () -> Void) where Label == Text {
        self.init(action: action) {
            Text(verbatim: content)
        }
    }
}
