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

public enum WorkoutSource: Codable, Hashable, RawRepresentable, Sendable, CustomStringConvertible {
    
    case native
    case imported
    case manuallyEntered
    case syncService(identifier: String)
    case unknown(rawValue: String)
    
    /// Indicates whether a workout with this source should be synced to sync services.
    /// - note: For now the only workouts that are synced outward are the ones recorded, imported or entered with this library.
    var shouldSyncOutward: Bool {
        switch self {
        case .native, .imported, .manuallyEntered: true
        case .syncService, .unknown: false
        }
    }
    
    // MARK: RawRepresentable
    
    public init(rawValue: String) {
        switch rawValue {
        case "native": self = .native
        case "imported": self = .imported
        case "manuallyEntered": self = .manuallyEntered
        case let value where value.hasPrefix("syncService:"):
            let identifier = String(value.dropFirst("syncService:".count))
            self = .syncService(identifier: identifier)
        default: self = .unknown(rawValue: rawValue)
        }
    }
    
    public var rawValue: String {
        switch self {
        case .native: "native"
        case .imported: "imported"
        case .manuallyEntered: "manuallyEntered"
        case .syncService(let identifier): "syncService:\(identifier)"
        case .unknown(let rawValue): rawValue
        }
    }
    
    public var description: String {
        switch self {
        case .native: .init(localized: "workout_source_native", bundle: .module)
        case .imported: .init(localized: "workout_source_imported", bundle: .module)
        case .manuallyEntered: .init(localized: "workout_source_manually_entered", bundle: .module)
        case .syncService(let identifier): .init(localized: "workout_source_sync_service_\(identifier)", bundle: .module)
        case .unknown(let rawValue): .init(localized: "workout_source_unknown_\(rawValue)", bundle: .module)
        }
    }
}
