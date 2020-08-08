//
//  WorkoutStatsSeriesSection.swift
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

struct WorkoutStatsSeriesSection {
    
    let type: SectionType
    let data: [(x: NSMeasurement, y: NSMeasurement)]
    var associatedDataSamples: [TempWorkoutSeriesDataSampleType]
    
    enum SectionType: Equatable {
        case active, paused, segmentOrLap(Bool)
        
        var color: UIColor {
            switch self {
            case .active:
                return .accentColor
            case .paused:
                return .secondaryColor
            case .segmentOrLap(let isEven):
                return isEven ? .accentColor : .accentColorSwapped
            }
        }
    }
    
}
