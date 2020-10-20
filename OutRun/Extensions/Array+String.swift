//
//  Array+String.swift
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

extension Array where Element == String {
    
    /**
     A function converting an `Array` of `String`s into a `Dictionary<String, String>` that has each element except the last as a key with the following element as the value
     - note: This is used in conjunction with `CoreStore` to form a `CoreStore.MigrationChain` from an `Array`
     */
    public func asConsequtiveDictionary() -> Dictionary<String, String> {
        
        let keysWithValues = self.dropLast().enumerated().map { (index, element) -> (String, String) in
            (element, self[index + 1])
        }
        return Dictionary(uniqueKeysWithValues: keysWithValues)
        
    }
    
}
