//
//  SpeedStatsView.swift
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

class SpeedStatsView: StatsView {
    
    let speedChart: LabelledDiagramView?
    
    init(stats: WorkoutStats) {
        
        var statViews = [StatView]()
        
        let avgSpeedView = LabelledDataView(title: LS["WorkoutStats.AverageSpeed"], measurement: stats.averageSpeed)
        statViews.append(avgSpeedView)
        
        if stats.hasRouteSamples {
            let topSpeedView = LabelledDataView(title: LS["WorkoutStats.TopSpeed"], measurement: stats.topSpeed)
            self.speedChart = LabelledDiagramView(title: LS["WorkoutStats.SpeedOverTime"])
            statViews.append(contentsOf: [topSpeedView, speedChart!])
        } else {
            self.speedChart = nil
        }
        self.speedChart?.disableSelection()
        
        super.init(title: LS["WorkoutStats.Speed"], statViews: statViews)
        
        if stats.hasRouteSamples {
            stats.querySpeeds { (success, series) in
                if let series = series {
                    let convertedSections = series.convertedForChartView(includeSamples: false, yUnit: UserPreferences.speedMeasurementType.safeValue)
                    self.speedChart?.setData(for: convertedSections)
                }
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
