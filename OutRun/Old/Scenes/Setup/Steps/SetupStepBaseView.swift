//
//  SetupStepView.swift
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

struct SetupStepBaseView<Content: View>: View {
    
    let headline: String
    let description: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .center, spacing: Constants.UI.Padding.small) {
            Text(headline)
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(description)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            content()
        }
    }
    
    internal init(
        headline: String,
        description: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.headline = headline
        self.description = description
        self.content = content
    }
}
