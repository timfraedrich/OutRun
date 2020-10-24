//
//  [FILENAME]
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

extension DataManager {
    
    /// An enumeration of possible errors comming up during the setup of data management.
    enum SetupError: Error, CustomDebugStringConvertible {
        
        /// CoreStore failed to add the SQLiteStorage to the DataStack.
        case failedToAddStorage(error: CoreStoreError)
        /// While performing intermediate mapping actions in between migrations, the mapping action closure returned with a failure indication.
        case intermediateMappingActionsFailed(version: ORDataModel.Type)
        
        var debugDescription: String {
            switch self {
            case .failedToAddStorage(let error):
                return "CoreStore failed to add the SQLiteStorage to the DataStack:\n \(error.debugDescription)"
            case .intermediateMappingActionsFailed(let version):
                return "While performing intermediate mapping actions in between migrations, the mapping action closure returned with a failure indication for version: \(version.identifier)"
            }
        }
    }
    
    /// An enumeration of possible errors comming up during the saving process of an object by the `DataManager`.
    enum SaveError: Error, CustomDebugStringConvertible {
        
        /// The object already exists inside the database.
        case alreadySaved
        /// The object could not be validated.
        case notValid
        /// There was an error while trying to insert the object into the database.
        case databaseError(error: CoreStoreError)
        
        var debugDescription: String {
            switch self {
            case .alreadySaved:
                return "The object already exists inside the database."
            case .notValid:
                return "The object could not be validated"
            case .databaseError(let error):
                return "There was an error while trying to insert the object into the database:\n\(error.debugDescription)"
            }
        }
    }
    
    /// An enumeration of possible errors comming up during the saving process of multiple objects by the `DataManager`.
    enum SaveMultipleError: Error, CustomDebugStringConvertible {
        
        /// Not all data sets provided could be saved to the database.
        case notAllSaved
        /// Not all objects could be valided, only the ones that could be, were saved to the database.
        case notAllValid
        /// There was an error while trying to insert the objects into the database.
        case dataBaseError(error: CoreStoreError)
    
        var debugDescription: String {
            switch self {
            case .notAllSaved:
                return "Not all data sets provided could be saved to the database."
            case .notAllValid:
                return "Not all objects could be valided, only the ones that could be, were saved to the database."
            case .dataBaseError(let error):
                return "There was an error while trying to insert the objects into the database:\n\(error.debugDescription)"
            }
        }
    }
    
}
