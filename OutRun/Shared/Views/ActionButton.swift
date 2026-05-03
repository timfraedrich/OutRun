import SwiftUI

struct ActionButton<Label: View>: View {
    
    let prominent: Bool
    let maxWidth: CGFloat?
    let action: () -> Void
    let label: () -> Label
    
    var body: some View {
        let label = label().frame(maxWidth: maxWidth).bold()
        Group {
            if prominent {
                Button(action: action) {
                    label.foregroundStyle(.white)
                }
                .buttonStyle(.actionProminent)
            } else {
                Button(action: action) {
                    label
                }
                .buttonStyle(.action)
            }
        }
        .controlSize(.large)
    }
    
    init(prominent: Bool = true, maxWidth: CGFloat? = .infinity, action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.prominent = prominent
        self.maxWidth = maxWidth
        self.action = action
        self.label = label
    }
    
    init(
        _ localizedString: LocalizedStringKey,
        prominent: Bool = true,
        maxWidth: CGFloat? = .infinity,
        action: @escaping () -> Void
    ) where Label == Text {
        self.init(prominent: prominent, maxWidth: maxWidth, action: action) {
            Text(localizedString)
        }
    }
    
    init(verbatim content: String, prominent: Bool = true, maxWidth: CGFloat? = .infinity, action: @escaping () -> Void) where Label == Text {
        self.init(prominent: prominent, maxWidth: maxWidth, action: action) {
            Text(verbatim: content)
        }
    }
    
    init(
        _ localizedString: LocalizedStringKey,
        systemImage: String,
        prominent: Bool = true,
        maxWidth: CGFloat? = .infinity,
        action: @escaping () -> Void
    ) where Label == SwiftUI.Label<Text, Image> {
        self.init(prominent: prominent, maxWidth: maxWidth, action: action) {
            SwiftUI.Label(localizedString, systemImage: systemImage)
        }
    }
}
