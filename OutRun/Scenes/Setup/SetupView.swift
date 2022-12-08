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
    
    private let numberOfSteps = 4
    private let skippableIndicies: [Int] = [2]
    @State private var finishedSteps: [Int:Bool] = [:]
    @State private var stepIndex: Int = 0
    
    private var isNextButtonEnabled: Binding<Bool> {
        Binding(
            get: { finishedSteps[stepIndex] ?? skippableIndicies.contains(stepIndex) },
            set: { finishedSteps[stepIndex] = $0 }
        )
    }
    
    var body: some View {
        AxisGeometryReader(axis: .horizontal) { outerWidth in
            VStack {
                ProgressView(progress: $stepIndex, total: numberOfSteps)
                
                GeometryReader { geometry in
                    let innerWidth = geometry.size.width
                    let spacing = (outerWidth - innerWidth) / 2
                    let offset = innerWidth + spacing
                    ZStack(alignment: .top) {
                        SetupFormalitiesView(canContinue: isNextButtonEnabled)
                        SetupUserInfoView(canContinue: isNextButtonEnabled)
                            .offset(x: 1 * offset)
                        SetupHealthView()
                            .offset(x: 2 * offset)
                        SetupPermissionsView(canContinue: isNextButtonEnabled)
                            .offset(x: 3 * offset)
                    }.offset(x: -offset * CGFloat(stepIndex))
                }
                .padding(.top, Constants.UI.Padding.big)
                .padding(.bottom, Constants.UI.Padding.normal)
                HStack {
                    Button("Previous", action: previous)
                        .font(.headline).opacity(stepIndex == 0 ? 0 : 1)
                    Spacer()
                    RoundedButton(nextButtonTitle, action: next)
                        .disabled(!isNextButtonEnabled.wrappedValue)
                }
            }
            .padding(.horizontal, Constants.UI.Padding.big)
            .padding(.vertical, Constants.UI.Padding.normal)
        }
    }
    
    private func previous() {
        withAnimation {
            stepIndex = max(0, stepIndex - 1)
        }
    }
    
    private var nextButtonTitle: String {
        stepIndex != numberOfSteps - 1 ? "Next" : "Finish"
    }
    
    private func next() {
        guard stepIndex < numberOfSteps - 1 else { finish(); return }
        withAnimation {
            stepIndex = min(numberOfSteps - 1, stepIndex + 1)
        }
    }
    
    private func finish() {
        // TODO: implement
    }
}

struct SetupView_Previews: PreviewProvider {
    static var previews: some View {
        SetupView()
    }
}
