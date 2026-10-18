//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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
