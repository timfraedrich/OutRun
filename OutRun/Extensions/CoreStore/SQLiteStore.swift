//
//  SQLiteStore.swift
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

extension SQLiteStore {
    
    /**
     A function to determine the current `ORDataModel` of the `SQLiteStore` from a provided migration chain
     - parameter migrationChain: the migration chain used to check for the current model
     - returns: the current `ORDataModel` of the `SQLiteStore`; if nil it could not be determined or the storage does not exist yet
     */
    internal func currentORModel(from migrationChain: [ORDataModel.Type]) -> ORDataModel.Type? {
        
        if let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: type(of: self).storeType,
            at: self.fileURL as URL,
            options: self.storeOptions
        ) {
            for type in migrationChain {
                if type.schema.rawModel().isConfiguration(withName: self.configuration, compatibleWithStoreMetadata: metadata) {
                    return type
                }
            }
        }
        
        return nil
        
    }
    
}
