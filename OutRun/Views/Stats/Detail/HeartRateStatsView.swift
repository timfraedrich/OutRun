//
//  HeartRateStatsView.swift
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
import HealthKit

class HeartRateStatsView: StatsView {
    
    
    let heartRateChart: LabelledDiagramView?
    
    init(stats: WorkoutStats) {
        
        var statViews = [StatView]()
        
        if stats.hasHeartRateData {
            self.heartRateChart = LabelledDiagramView(title: LS("WorkoutStats.HeartRateOverTime"))
            statViews.append(contentsOf: [heartRateChart!])
        } else {
            self.heartRateChart = nil
        }
        self.heartRateChart?.disableSelection()
        
        super.init(title: LS("WorkoutStats.HeartRate"), statViews: statViews)
        
        if stats.hasHeartRateData {
            stats.queryHeartRates { (success, series) in
                if let series = series {
                    let convertedSections = series.convertedForChartView(includeSamples: false, yUnit: UnitCount.count)
                    self.heartRateChart?.setData(for: convertedSections)
                }
            }
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
