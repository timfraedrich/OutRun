//
//  WelcomeView.swift
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

struct WelcomeView: View {
    
    @ObservedObject var viewModel: WelcomeViewModel
    
    var body: some View {
        VStack {
            Text(viewModel.titleLineOne)
                .font(.largeTitle)
                .bold()
            Text(viewModel.titleLineTwo)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.accentColor)
            Spacer()
            ForEach(viewModel.features, id: \.title) { viewModel in
                FeatureView(viewModel: viewModel)
            }
            Spacer()
            NavigationLink(isActive: $viewModel.showSetup) {
                SetupView()
            } label: {
                EmptyView()
            }
            ActionButton(viewModel.actionButtonTitle, action: {
                viewModel.showSetup = true
            })
        }
            .padding([.horizontal, .top], Constants.UI.Padding.big)
            .padding(.bottom, Constants.UI.Padding.normal)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(viewModel: WelcomeViewModel())
    }
}
