//
//  SetupUserInfoView.swift
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
import Combine

struct SetupUserInfoView: View {
    
    @Binding private var canContinue: Bool
    
    @State private var name: String = ""
    @State private var usesMetricSystem: Bool = true
    @State private var weight: Double?
    
    // TODO: replace with proper formatting
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    private var weightText: Binding<String> {
        Binding(
            get: { formatter.string(for: weight) ?? "" },
            set: {
                let number = formatter.number(from: $0)
                weight = number != nil ? Double(truncating: number!) : nil
            }
        )
    }
    
    var body: some View {
        SetupStepBaseView(
            headline: "But now let's talk about you!",
            description: "Lorem Ipsum this is a text about you? and such stuff which no one wants to read."
        ) {
            VStack(spacing: Constants.UI.Padding.small) {
                
                CardView {
                    HStack {
                        Text("Your name")
                            .bold()
                        Spacer()
                        TextField("Optional", text: $name)
                            .multilineTextAlignment(.trailing)
                            .fixedSize()
                    }
                }
                CardView {
                    HStack {
                        Text("Unit System")
                            .bold()
                        Spacer()
                        Picker("Unit System", selection: $usesMetricSystem) {
                            Text("Metric").tag(true)
                            Text("Imperial").tag(false)
                        }
                            .pickerStyle(.segmented)
                            .padding(.trailing, -8)
                            .fixedSize()
                    }
                }
                CardView {
                    HStack {
                        Text("Weight")
                            .bold()
                        Spacer()
                        TextField("Weight", text: weightText)
                            .multilineTextAlignment(.trailing)
                            .fixedSize()
                            .onReceive(Just(weight)) { weight in
                                self.weight = weight
                            }
                        Text(usesMetricSystem ? "kg" : "lb")
                    }
                }
                
            }.padding(.top, Constants.UI.Padding.big)
        }.onChange(of: shouldContinue) { shouldContinue in
            canContinue = shouldContinue
        }
    }
    
    private var shouldContinue: Bool { weight != nil }
    
    init(canContinue: Binding<Bool>) {
        self._canContinue = canContinue
    }
}

struct SetupUserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SetupUserInfoView(canContinue: .constant(false))
    }
}
