//
//  DataStack.swift
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

extension DataStack {
    
    /**
     Initialises a `DataStack` from a chain of `ORDataModel.Type`s and an optional current version model
     - parameter oRMigrationChain: an array of `ORDataModel.Type`s providing the migration chain
     - parameter oRDataModel: an `ORDataModel.Type` providing the current data model version
     */
    convenience init(oRMigrationChain: [ORDataModel.Type], oRDataModel: ORDataModel.Type? = nil) {
        
        if oRMigrationChain.isEmpty || (oRDataModel != nil && !oRMigrationChain.contains(where: { (type) -> Bool in type == oRDataModel })) {
            fatalError("[DataStack Extension] Initialisation failed because calling init(oRMigrationChain:oRDataModel:) with data model outside the migration chain is invalid")
        }
        
        let schemata = oRMigrationChain.map { (type) -> CoreStoreSchema in type.schema }
        let migrationDictionary = oRMigrationChain.map({ (type) -> String in type.identifier }).asConsequtiveDictionary()
        let schemaHistory = SchemaHistory(allSchema: schemata, migrationChain: MigrationChain(migrationDictionary), exactCurrentModelVersion: oRDataModel?.identifier)
        
        self.init(schemaHistory: schemaHistory)
    }
    
}
