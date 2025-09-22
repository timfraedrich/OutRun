import SwiftUI

struct ActionButton<Label: View>: View {
    
    let maxWidth: CGFloat?
    let action: () -> Void
    let label: () -> Label
    
    var body: some View {
        let button = Button(action: action) {
            label().bold().frame(maxWidth: maxWidth).foregroundStyle(.white)
        }
        .controlSize(.large)
        if #available(iOS 26, *) {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: .regular))
        }
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
