//
//  EnergyStatsView.swift
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

class EnergyStatsView: StatsView {
    
    private let disposeBag = DisposeBag()
    
    init(stats: WorkoutStats) {
        
        let totalEnergyView = LabelledDataView(title: LS["WorkoutStats.TotalEnergy"])
        let relativeTitle = CustomMeasurementFormatting.string(forUnit: UserPreferences.energyMeasurementType.safeValue, short: true) + " / " + CustomMeasurementFormatting.string(forUnit: UnitDuration.minutes, short: true)
        let relativeEnergyView = LabelledDataView(title: relativeTitle)
        
        stats.burnedEnergy.drive(totalEnergyView.rx.valueString).disposed(by: disposeBag)
        stats.burnedEnergyPerMinute.drive(relativeEnergyView.rx.valueString).disposed(by: disposeBag)
        
        super.init(
            title: LS["WorkoutStats.BurnedEnergy"],
            statViews: [totalEnergyView, relativeEnergyView]
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
}
