//
//  SetupPermissionsView.swift
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

struct SetupPermissionsView: View {
    
    @Binding private var canContinue: Bool
    
    @State private var grantedLocationAccess = false
    @State private var grantedHealthAccess = false
    @State private var grantedMotionAccess = false
    
    var body: some View {
        SetupStepBaseView(
            headline: "Now we just need your permission",
            description: "Lorem Ipsum this is a text about permissions and such stuff which no one wants to read."
        ) {
            VStack(spacing: Constants.UI.Padding.small) {
                
                PermissionView(
                    title: "Location",
                    granted: $grantedLocationAccess) {
                        // show explanation
                    } showPermissionMenu: {
                        // show permission menu
                        grantedLocationAccess = true
                    }
                
                // TODO: only display if needed
                PermissionView(
                    title: "Apple Health",
                    granted: $grantedHealthAccess) {
                        // show explanation
                    } showPermissionMenu: {
                        // show permission menu
                    }

                PermissionView(
                    title: "Motion (Optional)",
                    granted: $grantedMotionAccess) {
                        // show explanation
                    } showPermissionMenu: {
                        // show permission menu
                    }
                
            }.padding(.top, Constants.UI.Padding.big)
        }.onChange(of: shouldContinue) { shouldContinue in
            canContinue = shouldContinue
        }
    }
    
    private var shouldContinue: Bool { grantedLocationAccess /*&& if neccessary health*/ }
    
    init(canContinue: Binding<Bool>) {
        self._canContinue = canContinue
    }
}

struct SetupPermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        SetupPermissionsView(canContinue: .constant(false))
    }
}
