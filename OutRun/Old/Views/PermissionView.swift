//
//  PermissionView.swift
//
//  OutRun
//  Copyright (C) 2022 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI

struct PermissionView: View {
    
    private let title: String
    @Binding private var granted: Bool
    private let showExplanation: () -> Void
    private let showPermissionMenu: () -> Void
    
    var body: some View {
        CardView {
            HStack {
                Button(action: showExplanation) {
                    Text(title).bold()
                }
                Spacer()
                Button(action: showPermissionMenu) {
                    ZStack {
                        Text("GRANT")
                            .opacity(granted ? 0 : 1)
                        Image(systemName: "checkmark")
                            .opacity(granted ? 1 : 0)
                    }
                        .foregroundColor(Color.white)
                        .font(.subheadline.bold())
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 16)
                .background(granted ? Color.accentColor : Color.gray)
                .clipShape(Capsule())
                .animation(.easeOut)
            }
        }
    }
    
    init(
        title: String,
        granted: Binding<Bool>,
        showExplanation: @escaping () -> Void,
        showPermissionMenu: @escaping () -> Void) {
        self.title = title
        self._granted = granted
        self.showExplanation = showExplanation
        self.showPermissionMenu = showPermissionMenu
    }
}

struct SetupPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionView(
            title: "Permission",
            granted: .constant(false),
            showExplanation: {},
            showPermissionMenu: {}
        )
    }
}
