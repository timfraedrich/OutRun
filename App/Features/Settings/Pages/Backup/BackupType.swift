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
import SwiftUI

enum BackupType: String, CaseIterable, Sendable, Identifiable {
    
    case model = "backup"
    case gpx = "gpx"
    case legacy = "legacy"
    
    var id: Int {
        hashValue
    }
    
    var fileExtension: String {
        switch self {
        case .model: "json"
        case .gpx: "gpx"
        case .legacy: "orbup"
        }
    }
    
    /// Indicates whether the data is exported to a zip archive.
    var useZipCompression: Bool {
        switch self {
        case .model: true
        case .gpx, .legacy: false
        }
    }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .model: "backup_type_title_model"
        case .gpx: "backup_type_title_gpx"
        case .legacy: "backup_type_title_legacy"
        }
    }
    
    static let exportableCases: [BackupType] = [.model, .gpx]
}
