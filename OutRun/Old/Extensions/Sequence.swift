//
//  Sequence.swift
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

extension Sequence {
    
    func groupBy<GroupingType : Comparable>(keyFunc: (Iterator.Element) -> GroupingType) -> Dictionary<GroupingType, [Iterator.Element]> {
        
        var dictionary: Dictionary<GroupingType, [Iterator.Element]> = [:]
        
        for element in self {
            let key = keyFunc(element)
            
            if dictionary.keys.contains(key) {
                var newValue = dictionary[key] ?? []
                newValue.append(element)
                dictionary.updateValue(newValue, forKey: key)
            } else {
                dictionary.updateValue([element], forKey: key)
            }
        }
        
        return dictionary
    }
    
}
