//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
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

public enum DynamicTimeInterval: Hashable, Sendable, Codable {

    case constant(TimeInterval)
    case increasing(since: Date, offset: TimeInterval)
    
    public func timeInterval(for referenceDate: Date) -> TimeInterval {
        switch self {
        case .constant(let timeInterval):
            return timeInterval
        case .increasing(let startDate, let offset):
            guard referenceDate > startDate.addingTimeInterval(offset) else { return .zero }
            return startDate.addingTimeInterval(offset).distance(to: referenceDate)
        }
    }
}
