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

struct SettingsOpenURLButton<Label: View>: View {
    
    @Environment(\.openURL) private var openURL
    private let urlString: String
    private let label: () -> Label
    
    var body: some View {
        NavigationLinkButton(action: openURLAction, label: label)
            .tint(.primary)
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
