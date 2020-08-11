//
//  Double.swift
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

extension Double {
    
    /**
     Rounds this value to a specified decimal place using the specifed `FloatingPointRoundingRule`
     - parameter decimalPlaces: the maximum number of decimal places the value should have
     - parameter rule: the rule by which the value will be rounded
     */
    mutating func round(decimalPlaces: Int = 0, rule: FloatingPointRoundingRule) {
        
        self = self.rounded(decimalPlaces: decimalPlaces, rule: rule)
    }
    
    /**
     Returns this value rounded to a specified decimal place using the specifed `FloatingPointRoundingRule`
     - parameter decimalPlaces: the maximum number of decimal places the value should have
     - parameter rule: the rule by which the value will be rounded
     - returns: the rounded value
     */
    func rounded(decimalPlaces: Int = 0, rule: FloatingPointRoundingRule) -> Double {
        
        let roundingFactor = Double(pow(10, Double(decimalPlaces)))
        
        return ( self * roundingFactor ).rounded(rule) / roundingFactor
        
    }
    
}
