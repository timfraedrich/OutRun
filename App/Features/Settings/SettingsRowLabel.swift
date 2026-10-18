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

struct SettingsRowLabel<TitleView: View, IconView: View>: View {
    
    @Environment(\.fontResolutionContext) private var fontContext
    private let title: () -> TitleView
    private let icon: () -> IconView
    
    private var iconBackgroundSize: CGFloat {
        if #available(iOS 26.0, *) {
            Font.body.resolve(in: fontContext).pointSize + Spacing.regular.rawValue
        } else {
            UIFont.preferredFont(forTextStyle: .body).pointSize + Spacing.regular.rawValue
        }
    }
    
    var body: some View {
        Label(title: title, icon: iconWithBackground)
    }
    
    @ViewBuilder
    private func iconWithBackground() -> some View {
        ZStack {
            Rectangle().frame(width: iconBackgroundSize, height: iconBackgroundSize).opacity(0.2)
            icon().padding(.extraSmall)
        }
        .clipShape(.rect(cornerRadius: .small))
        .foregroundStyle(.tint)
    }
    
    init(@ViewBuilder title: @escaping () -> TitleView, @ViewBuilder icon: @escaping () -> IconView) {
        self.title = title
        self.icon = icon
    }
}

#Preview {
    List {
        SettingsRowLabel {
            Text("Units")
        } icon: {
            Image(systemName: "ruler.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        SettingsRowLabel {
            Text("Apple Health")
        } icon: {
            Image(systemName: "heart.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .offset(x: 3, y: -3)
        }
    }
}
