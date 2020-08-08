//
//  Units.swift
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

protocol StandardizedUnit {
    
    static var standardUnit: Unit { get }
    static var standardBigUnit: Unit { get }
    static var standardBigLocalUnit: Unit { get }
    static var standardSmallLocalUnit: Unit { get }
    
}

extension UnitLength: StandardizedUnit {
    
    static var standardUnit: Unit {
        get {
            return UnitLength.meters
        }
    }
    
    static var standardBigUnit: Unit {
        get {
            return UnitLength.kilometers
        }
    }
    
    static var standardBigLocalUnit: Unit {
        get {
            return Locale.current.usesMetricSystem ? UnitLength.kilometers : UnitLength.miles
        }
    }
    
    static var standardSmallLocalUnit: Unit {
        get {
            return Locale.current.usesMetricSystem ? UnitLength.meters : UnitLength.feet
        }
    }
}

extension UnitSpeed: StandardizedUnit {
    
    static var standardUnit: Unit {
        get {
            return UnitSpeed.metersPerSecond
        }
    }
    
    static var standardBigUnit: Unit {
        get {
            return UnitSpeed.kilometersPerHour
        }
    }
    
    static var standardBigLocalUnit: Unit {
        get {
            return Locale.current.usesMetricSystem ? UnitSpeed.kilometersPerHour : UnitSpeed.milesPerHour
        }
    }
    
    static var standardSmallLocalUnit: Unit {
        get {
            return Locale.current.usesMetricSystem ? UnitSpeed.metersPerSecond : UnitSpeed(symbol: "ft/s", converter: UnitLength.feet.converter)
        }
    }
}

extension UnitEnergy: StandardizedUnit {
    
    static var standardUnit: Unit {
        get {
            return UnitEnergy.kilocalories
        }
    }
    
    static var standardBigUnit: Unit {
        get {
            return standardUnit
        }
    }
    
    static var standardBigLocalUnit: Unit {
        get {
            return standardUnit
        }
    }
    
    static var standardSmallLocalUnit: Unit {
        get {
            return UnitEnergy.calories
        }
    }
}

extension UnitMass: StandardizedUnit {
    
    static var standardUnit: Unit {
        get {
            return UnitMass.kilograms
        }
    }
    
    static var standardBigUnit: Unit {
        get {
            return standardUnit
        }
    }
    
    static var standardBigLocalUnit: Unit {
        get {
            return Locale.current.usesMetricSystem ? UnitMass.kilograms : UnitMass.pounds
        }
    }
    
    static var standardSmallLocalUnit: Unit {
        get {
            return Locale.current.usesMetricSystem ? UnitMass.grams : UnitMass.ounces
        }
    }
}
