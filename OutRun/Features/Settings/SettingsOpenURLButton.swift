import SwiftUI

struct SettingsOpenURLButton<Label: View>: View {
    
    @Environment(\.openURL) private var openURL
    private let urlString: String
    private let label: () -> Label
    
    var body: some View {
        NavigationLinkButton(action: openURLAction, label: label)
    }
    
    init(_ urlString: String, @ViewBuilder label: @escaping () -> Label) {
        self.urlString = urlString
        self.label = label
    }
    
    private func openURLAction() {
        guard let url = URL(string: urlString) else { return }
        openURL.callAsFunction(url)
    }
}
