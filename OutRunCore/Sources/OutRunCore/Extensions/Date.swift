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

public extension Date {
    
    /// The Unix timestamp in milliseconds.
    var unixTimestamp: Int { Int(timeIntervalSince1970 * 1000) }
    
    /// Creates a ``Date`` instance from a Unix timestamp in milliseconds.
    init(unixTimestamp: Int) {
        self.init(timeIntervalSince1970: .init(unixTimestamp) / 1000)
    }
}
