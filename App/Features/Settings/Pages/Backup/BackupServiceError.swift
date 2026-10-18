//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation

enum BackupServiceError: LocalizedError {
    
    /// The file provided by the user could not be read as a backup.
    case backupNotReadable
    /// There is no data to create a backup with.
    case noDataToBackUp
    /// There was an error while encoding the workout data to create a backup.
    case couldNotEncodeData
    /// Could not restore workout data from the provided file, because it is not supported.
    case unsupportedFile
    
    var errorDescription: String? {
        switch self {
        case .backupNotReadable: .init(localized: "backup_service_error_backup_not_readable")
        case .noDataToBackUp: .init(localized: "backup_service_error_no_data_to_back_up")
        case .couldNotEncodeData: .init(localized: "backup_service_error_could_not_encode_data")
        case .unsupportedFile: .init(localized: "backup_service_error_unsupported_file")
        }
    }
}
