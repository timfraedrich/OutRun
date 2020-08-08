//
//  CustomMeasurementFormatting.swift
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

import Foundation

class CustomMeasurementFormatting {
    
    static func string(forMeasurement measurement: NSMeasurement, type: FormattingMeasurementType = .auto, rounding: FormattingRoundingType = .twoDigits) -> String {
        
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        
        switch rounding {
        case .wholeNumbers:
            formatter.numberFormatter.roundingIncrement = 1
        case .oneDigit:
            formatter.numberFormatter.roundingIncrement = 0.1
        case .twoDigits:
            formatter.numberFormatter.roundingIncrement = 0.01
        case .fourDigits:
            formatter.numberFormatter.roundingIncrement = 0.0001
        case .none:
            break
        }
        
        switch type {
        case .clock:
            let seconds = measurement.converting(to: UnitDuration.seconds).value
            let timeFormatter = DateComponentsFormatter()
            timeFormatter.unitsStyle = .positional
            timeFormatter.allowedUnits = [.hour, .minute, .second]
            timeFormatter.zeroFormattingBehavior = .pad
            return timeFormatter.string(from: seconds) ?? "Error"
        case .distance:
            return formatter.string(from: measurement.converting(to: UserPreferences.distanceMeasurementType.safeValue))
        case .altitude:
            return formatter.string(from: measurement.converting(to: UserPreferences.altitudeMeasurementType.safeValue))
        case .speed:
            return formatter.string(from: measurement.converting(to: UserPreferences.speedMeasurementType.safeValue))
        case .energy:
            return formatter.string(from: measurement.converting(to: UserPreferences.energyMeasurementType.safeValue))
        case .weight:
            return formatter.string(from: measurement.converting(to: UserPreferences.weightMeasurementType.safeValue))
        default:
            formatter.unitOptions = .naturalScale
            return formatter.string(from: measurement as Measurement)
        }
    }
    
    static func string(forUnit unit: Unit, short: Bool = false) -> String {
        let formatter = MeasurementFormatter()
        return short ? unit.symbol : formatter.string(from: unit)
    }
    
    enum FormattingMeasurementType {
        case clock, time
        case distance, altitude
        case speed
        case energy
        case weight
        case auto
        
        init(for unit: Unit, asClock: Bool = false, asAltitude: Bool = false) {
            switch unit {
            case is UnitDuration:
                self = asClock ? .clock : .time
            case is UnitLength:
                self = asAltitude ? .altitude : .distance
            case is UnitSpeed:
                self = .speed
            case is UnitEnergy:
                self = .energy
            case is UnitMass:
                self = .weight
            default:
                self = .auto
            }
        }
    }
    
    enum FormattingRoundingType {
        case wholeNumbers, oneDigit, twoDigits, fourDigits, none
    }
    
}
