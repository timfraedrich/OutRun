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

/// Enum whose cases indicate whether and if so since when changes should be synchronized.
public enum SyncMode: Codable, Hashable, Sendable {
    
    /// No workouts or their changes should be synced to the service.
    case disabled
    /// All workouts and their changes should be synced to the service.
    case enabled
    /// Workouts and their changes should be synced to the service if the workout was created after the specified date.
    case enabledFrom(date: Date)
    
    var isEnabled: Bool {
        switch self {
        case .enabled, .enabledFrom: true
        case .disabled: false
        }
    }
    
    var startDate: Date? {
        switch self {
        case .disabled: nil
        case .enabled: .distantPast
        case .enabledFrom(let date): date
        }
    }
}
