//
//  ActionButton.swift
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

struct ActionButton: View {
    
    @Binding private var text: String
    private let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .foregroundColor(Color.white)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.white)
            }
            .font(Font.headline)
            .foregroundColor(Color.white)
            .padding(Constants.UI.Padding.normal)
            .background(Color.accentColor)
            .cornerRadius(Constants.UI.CornerRadius.normal)
        }
    }
    
    init(_ text: Binding<String>, action: @escaping () -> Void) {
        self._text = text
        self.action = action
    }
    
    init(_ text: String, action: @escaping () -> Void) {
        self._text = .constant(text)
        self.action = action
    }
}
