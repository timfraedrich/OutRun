//
//  DataQueryManager.swift
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
import CoreStore
import CoreLocation

extension DataManager {
    
    /**
     Queries the an object comforming to `ORDataType` with the provided `UUID` from the database.
     - parameter uuid: the `UUID` of the workout that is supposed to be returned
     - parameter transaction: an optional `AsynchronousDataTransaction` to be provided if the workout needs to be queried during a tranaction; if `nil` the object will be queried from the `DataManager.dataStack`
     - returns: the wanted `ORDataType` object if one could be found in the database; if the object could not be found, this function will return `nil`
     */
    public static func queryObject<ObjectType: ORDataType>(from uuid: UUID, transaction: AsynchronousDataTransaction? = nil) -> ObjectType? {
        
        let object = try? (transaction as FetchableSource? ?? dataStack).fetchOne(From<ObjectType>().where(\._uuid == uuid))
        return object
        
    }
    
    /**
     Queries the count for objects of the given `ORDataType` and `UUID` returning whether it has duplicates in the database.
     - parameter uuid: the `UUID` of the workout being checked for duplicates
     - parameter objectType: the type of the object being checked for duplicates
     - returns: `true` if the queried count is anything other than 0 meaning there are workouts with the given `UUID` present in the database.
     */
    public static func objectHasDuplicate<ObjectType: ORDataType>(uuid: UUID, objectType: ObjectType.Type) -> Bool {
        
        if let count = try? dataStack.fetchCount(From<ObjectType>().where(\._uuid == uuid)) {
            return count != 0
        }
        
        return false
        
    }
    
}
