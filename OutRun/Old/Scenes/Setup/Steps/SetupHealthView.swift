//
//  SetupHealthView.swift
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

struct SetupHealthView: View {
    
    @State private var wantsToSyncWorkouts = false
    @State private var wantsToAutoImport = false
    @State private var wantsToSyncWeight = false
    
    var body: some View {
        SetupStepBaseView(
            headline: "Apple Health",
            description: "Lorem Ipsum this is a text about syncing with Apple Health and such stuff which no one wants to read."
        ) {
            VStack(spacing: Constants.UI.Padding.small) {
                
                CardView {
                    Toggle(isOn: $wantsToSyncWorkouts) {
                        Text("Sync Workouts").bold()
                    }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }.onChange(of: wantsToSyncWorkouts) { wantsToSyncWorkouts in
                    // set preference
                    guard !wantsToSyncWorkouts else { return }
                    wantsToAutoImport = false
                }
                
                CardView {
                    Toggle(isOn: $wantsToAutoImport) {
                        Text("Auto-Import Workouts").bold()
                            .opacity(wantsToSyncWorkouts ? 1 : 0.5)
                    }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .disabled(!wantsToSyncWorkouts)
                }.onChange(of: wantsToAutoImport) { wantsToAutoImport in
                    // set preference
                }
                
                CardView {
                    Toggle(isOn: $wantsToSyncWeight) {
                        Text("Sync Weight").bold()
                    }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }.onChange(of: wantsToSyncWeight) { wantsToSyncWeight in
                    // set preference
                }
                
            }.padding(.top, Constants.UI.Padding.big)
        }
    }
}

struct SetupHealthView_Previews: PreviewProvider {
    static var previews: some View {
        SetupHealthView()
    }
}
