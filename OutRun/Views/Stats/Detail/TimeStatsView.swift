//
//  TimeStatsView.swift
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

import UIKit

class TimeStatsView: StatsView {
    
    init(stats: WorkoutStats) {
        
        var statViews = [StatView]()
        
        let activeView = LabelledDataView(title: LS["Workout.ActiveDuration"])
        let pauseView = LabelledDataView(title: LS["Workout.PauseDuration"])
        let startView = LabelledDataView(title: LS["WorkoutStats.StartTime"])
        let endView = LabelledDataView(title: LS["WorkoutStats.EndTime"])
        
        if !stats.hasWorkoutPauses {
            statViews.append(contentsOf: [activeView, startView, endView])
        } else {
            statViews.append(contentsOf: [activeView, pauseView, startView, endView])
        }
        
        super.init(title: LS["WorkoutStats.Time"], statViews: statViews)
        
        self.backgroundColor = .backgroundColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
