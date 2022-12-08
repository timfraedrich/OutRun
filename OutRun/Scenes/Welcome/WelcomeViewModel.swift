//
//  WelcomeViewModel.swift
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

import Foundation

class WelcomeViewModel: ObservableObject {
    
    @Published var showSetup = false
    
    let titleLineOne = "Welcome to"
    let titleLineTwo = "OutRun"
    let features = [
        FeatureViewModel(
            title: "Accurate Tracking",
            description: "Record your running, walking, cycling, skating or hiking workouts.",
            systemImageName: "location.viewfinder"),
        FeatureViewModel(
            title: "Detailed Statistics",
            description: "Look at them stats in much detail and stuff, and here comes some additional text.",
            systemImageName: "chart.xyaxis.line"),
        FeatureViewModel(
            title: "Privacy Smth Smth",
            description: "Much privacy, no sharing, data stays on your device whatever happens lol, smth smth.",
            systemImageName: "lock.shield")
    ]
    let actionButtonTitle = "Begin Setup"
    
}
