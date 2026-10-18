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

enum LegacyBackupError: LocalizedError {
    
    /// The provided backup file does not have the correct format, it might be corrupted.
    case corruptedData
    /// The backup is missing a version.
    case missingVersion
    /// The backup version is not supported by this app.
    case invalidVersion
    
    var errorDescription: String? {
        switch self {
        case .corruptedData: .init(localized:"legacy_backup_error_corrupted_data")
        case .missingVersion: .init(localized:"legacy_backup_error_missing_version")
        case .invalidVersion: .init(localized:"legacy_backup_error_invalid_version")
        }
    }
}
