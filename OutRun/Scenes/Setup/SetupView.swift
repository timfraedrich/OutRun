//
//  FormalitiesView.swift
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

struct SetupView: View {
    
    @ObservedObject var viewModel: SetupViewModel
    
    var body: some View {
        AxisGeometryReader(axis: .horizontal) { outerWidth in
            VStack {
                ProgressView(progress: viewModel.stepIndex, total: viewModel.numberOfSteps)
                
                GeometryReader { geometry in
                    let innerWidth = geometry.size.width
                    let spacing = (outerWidth - innerWidth) / 2
                    let offset = innerWidth + spacing
                    ZStack(alignment: .top) {
                        SetupFormalitiesView(canContinue: viewModel.isNextButtonEnabled)
                        SetupUserInfoView(canContinue: viewModel.isNextButtonEnabled)
                            .offset(x: 1 * offset)
                        SetupHealthView()
                            .offset(x: 2 * offset)
                        SetupPermissionsView(canContinue: viewModel.isNextButtonEnabled)
                            .offset(x: 3 * offset)
                    }.offset(x: -offset * CGFloat(viewModel.stepIndex))
                }
                .padding(.top, Constants.UI.Padding.big)
                .padding(.bottom, Constants.UI.Padding.normal)
                HStack {
                    Button(viewModel.previousButtonTitle, action: viewModel.previous)
                        .font(.headline).opacity(viewModel.stepIndex == 0 ? 0 : 1)
                    Spacer()
                    RoundedButton(viewModel.nextButtonTitle, action: viewModel.next)
                        .disabled(!viewModel.isNextButtonEnabled.wrappedValue)
                }
            }
            .padding(.horizontal, Constants.UI.Padding.big)
            .padding(.vertical, Constants.UI.Padding.normal)
        }
    }
}
