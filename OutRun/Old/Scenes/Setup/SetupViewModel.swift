//
//  SetupViewModel.swift
//
//  OutRun
//  Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>
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

class SetupViewModel: ObservableObject {
    
    @Published private(set) var finishedSteps: [Int:Bool] = [:]
    @Published private(set) var stepIndex: Int = 0
    
    let numberOfSteps = 4
    let skippableIndicies: [Int] = [2]
    
    var isNextButtonEnabled: Binding<Bool> {
        Binding(
            get: { self.finishedSteps[self.stepIndex] ?? self.skippableIndicies.contains(self.stepIndex) },
            set: { self.finishedSteps[self.stepIndex] = $0 }
        )
    }
    
    let previousButtonTitle = "Previous"
    var nextButtonTitle: String {
        stepIndex != numberOfSteps - 1 ? "Next" : "Finish"
    }
    
    func previous() {
        withAnimation { stepIndex = max(0, stepIndex - 1) }
    }
    
    func next() {
        guard stepIndex < numberOfSteps - 1 else { finish(); return }
        withAnimation { stepIndex = min(numberOfSteps - 1, stepIndex + 1) }
    }
    
    func finish() {
        withAnimation(.easeInOut) {
            UserPreferences.isSetUp.value = true
        }
    }
}
