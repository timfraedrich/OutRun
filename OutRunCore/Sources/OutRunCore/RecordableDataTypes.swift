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

/// An OptionSet of data that can be recorded during a workout.
public struct RecordableDataTypes: OptionSet, Sendable, Hashable {
    
    public let rawValue: Int
    
    public static let location = RecordableDataTypes(rawValue: 1 << 0)
    public static let preciseAltitude = RecordableDataTypes(rawValue: 1 << 1)
    public static let steps = RecordableDataTypes(rawValue: 1 << 2)
    
    public static let all: RecordableDataTypes = [.location, .preciseAltitude, .steps]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
