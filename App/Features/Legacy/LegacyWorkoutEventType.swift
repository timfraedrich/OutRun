//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import OutRunCore

enum LegacyWorkoutEventType: Int {
    
    case pause = 0
    case autoPause = 1
    case resume = 2
    case autoResume = 3
    case lap = 4
    case marker = 5
    case segment = 6
    case unknown = -1
    
    init(rawValue: Int) {
        switch rawValue {
        case 0: self = .pause
        case 1: self = .autoPause
        case 2: self = .resume
        case 3: self = .autoResume
        case 4: self = .lap
        case 5: self = .marker
        case 6: self = .segment
        default: self = .unknown
        }
    }
}

extension Calculation.PauseEventType {
    
    init?(legacyEventType: LegacyWorkoutEventType) {
        switch legacyEventType {
        case .pause: self = .pause
        case .autoPause: self = .autoPause
        case .resume: self = .resume
        case .autoResume: self = .autoResume
        default: return nil
        }
    }
}
