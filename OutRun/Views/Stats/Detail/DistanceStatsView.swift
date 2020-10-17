//
//  DistanceStatsView.swift
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
import Charts

class DistanceStatsView: StatsView {
    
    let altitudeChart: LabelledDiagramView?
    
    init(stats: WorkoutStats) {
        
        var statViews = [StatView]()
        
        statViews.append(LabelledDataView(title: LS["Workout.Distance"], measurement: stats.distance))
        if stats.steps != nil {
            statViews.append(LabelledDataView(title: stats.type == .cycling ? LS["Workout.Strokes"] : LS["Workout.Steps"], measurement: stats.steps!))
        }
        if stats.ascendingAltitude != nil {
            statViews.append(LabelledDataView(title: LS["WorkoutStats.AscendingAltitude"], measurement: stats.ascendingAltitude, isAltitude: true))
        }
        if stats.descendingAltitude != nil {
            statViews.append(LabelledDataView(title: LS["WorkoutStats.DescendingAltitude"], measurement: stats.descendingAltitude, isAltitude: true))
        }
        self.altitudeChart = stats.hasRouteSamples ? LabelledDiagramView(title: LS["WorkoutStats.AltitudeOverTime"]) : nil
        if let altit = self.altitudeChart {
            statViews.append(altit)
        }
        self.altitudeChart?.disableSelection()
        
        super.init(title: LS["Workout.Distance"], statViews: statViews)
        
        if stats.hasRouteSamples {
            stats.queryAltitudes { (success, series) in
                if let series = series {
                    let convertedSections = series.convertedForChartView(includeSamples: false, yUnit: UserPreferences.altitudeMeasurementType.safeValue)
                    self.altitudeChart?.setData(for: convertedSections)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
