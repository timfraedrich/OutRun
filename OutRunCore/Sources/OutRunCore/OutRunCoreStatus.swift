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

public enum OutRunCoreStatus: Equatable, Sendable {
    
    /// The core is currently being set up.
    case initializing
    /// The setup has not been performed. Required data for setup should be collected and ``OutRunCore/setup(for:)`` should be called.
    case needsSetup
    /// The core is fully initialized and ready for use.
    case initialized
    /// The core failed internally due to the provided error.
    case failed(Error)
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing), (.needsSetup, .needsSetup), (.initialized, .initialized), (.failed, .failed): true
        default: false
        }
    }
}
