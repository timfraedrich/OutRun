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
import RxSwift
import RxCocoa

class SpeedStatsView: StatsView {
    
    private let disposeBag = DisposeBag()
    
    init(stats: WorkoutStats) {
        
        let avgSpeedView = LabelledDataView(title: LS["WorkoutStats.AverageSpeed"])
        let topSpeedView = LabelledDataView(title: LS["WorkoutStats.TopSpeed"])
        let speedChart = LabelledDiagramView(title: LS["WorkoutStats.SpeedOverTime"])
        
        stats.averageSpeed.drive(avgSpeedView.rx.valueString).disposed(by: disposeBag)
        if stats.hasRouteSamples {
            stats.topSpeed.drive(topSpeedView.rx.valueString).disposed(by: disposeBag)
            stats.speedOverTime.drive(speedChart.rx.data()).disposed(by: disposeBag)
            Driver.just(true).drive(speedChart.rx.isDisabled).disposed(by: disposeBag)
        }
        
        let statViews: [StatView] = [avgSpeedView] + (stats.hasRouteSamples ? [topSpeedView, speedChart] : [])
        
        super.init(title: LS["WorkoutStats.Speed"], statViews: statViews)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
