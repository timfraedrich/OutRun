
//
//  WorkoutStatsSeries.swift
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

class WorkoutStatsSeries {
    
    let sectioningType: SectioningType
    let sections: [WorkoutStatsSeriesSection]
    
    init(sectioningType: SectioningType, sections: [WorkoutStatsSeriesSection]) {
        self.sectioningType = sectioningType
        self.sections = sections
    }
    
    func convertedForChartView(includeSamples: Bool, yUnit: Unit) -> [(color: UIColor, data: [(Measurement<Unit>, Measurement<Unit>)], samples: [TempWorkoutSeriesDataSampleType])] {
        return self.sections.map { (section) -> (color: UIColor, data: [(Measurement<Unit>, Measurement<Unit>)], samples: [TempWorkoutSeriesDataSampleType]) in
            let convertedData = section.data.map { (time, yValue) -> (Measurement<Unit>, Measurement<Unit>) in
                return (
                    time.converting(to: UnitDuration.minutes),
                    yValue.converting(to: yUnit)
                )
            }
            return (
                color: section.type.color,
                data: convertedData,
                samples: includeSamples ? section.associatedDataSamples : []
            )
        }
    }
    
    enum SectioningType {
        case activeAndPaused
    }
}
