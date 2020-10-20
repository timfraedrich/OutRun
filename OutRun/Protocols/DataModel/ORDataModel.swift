//
//  ORDataModel.swift
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

import CoreStore

/// A protocol used to define data models for the data base this application saves workouts in.
protocol ORDataModel {
    
    /// A `String` to identify the data model in a CoreData/CoreStore context
    static var identifier: String { get }
    
    /// The `CoreStoreSchema` of the data model used to setup the datastack
    static var schema: CoreStoreSchema { get }
    
    /// The `CustomSchemaMappingProvider` of this data model version used to migrate from the last; if `nil` the model should be the first
    static var mappingProvider: CustomSchemaMappingProvider? { get }
    
    /// An array of this data models and the ones coming before it in chronologial order used to perform migrations
    static var migrationChain: [ORDataModel.Type] { get }
    
}

extension ORDataModel {
    
    /**
     A fuction to determine if a data model contains all elements of another in its migration chain
     - parameter otherModel: the model `self` is supposed to be compared to
     - returns: A `Bool` indicating if all elements of `otherModel` are included in `self`s migration chain
     */
    static func containsAllElements(of otherModel: ORDataModel.Type) -> Bool {
        return self.migrationChain.allSatisfy({ (type) -> Bool in
            otherModel.migrationChain.contains { (otherType) -> Bool in
                otherType == type
            }
        })
    }
    
    /**
     A fuction to determine if a data model is more recent than another.
     - parameter otherModel: the model `self` is supposed to be compared to
     - returns: a `Bool` indicating if `self`s is more recent than `otherModel`
     - warning: Trying to compare incompatible models will lead to a fatal error which crashes the application
     */
    static func isSuccessor(to otherModel: ORDataModel.Type) -> Bool {
        if !(self.containsAllElements(of: otherModel) || otherModel.containsAllElements(of: self)) {
            fatalError("[ORDataModel] Tried to determine successor of incompatible ORDataModels")
        }
        return self.migrationChain.count > otherModel.migrationChain.count
    }
    
}
