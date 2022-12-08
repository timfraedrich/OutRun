//
//  SetupFormalitiesView.swift
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

struct SetupFormalitiesView: View {
    
    @Binding private var canContinue: Bool
    
    @State private var acceptedTerms = false
    @State private var acceptedPrivacy = false
    
    var body: some View {
        SetupStepBaseView(
            headline: "Let's start with the formalities!",
            description: "Lorem Ipsum this is a text about formalities and such stuff which no one wants to read."
        ) {
            VStack(spacing: Constants.UI.Padding.small) {
                
                CardView {
                    Toggle(isOn: $acceptedTerms) {
                        Button {
                            // open terms
                        } label: {
                            Text("Terms of Service").bold()
                        }
                    }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                
                CardView {
                    Toggle(isOn: $acceptedPrivacy) {
                        Button {
                            // open privacy
                        } label: {
                            Text("Privacy Policy").bold()
                        }
                    }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                
            }.padding(.top, Constants.UI.Padding.big)
        }.onChange(of: shouldContinue) { shouldContinue in
            canContinue = shouldContinue
        }
    }
    
    private var shouldContinue: Bool { acceptedTerms && acceptedPrivacy }
    
    init(canContinue: Binding<Bool>) {
        self._canContinue = canContinue
    }
}

struct SetupFormalitiesView_Previews: PreviewProvider {
    static var previews: some View {
        SetupFormalitiesView(canContinue: .constant(false))
    }
}
