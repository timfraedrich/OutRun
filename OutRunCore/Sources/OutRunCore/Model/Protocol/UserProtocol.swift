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

public protocol UserProtocol: Equatable {
    
    /// Optional identifier to identify a user with an external service.
    var id: UUID? { get set }
    /// The users name.
    /// - warning: This property should not be empty.
    var name: String { get set }
    var birthday: Day? { get set }
    /// The users weight in kilograms.
    var weight: Double? { get set }
    var sex: Sex? { get set }
    
    var preferences: RawPreferences { get set }
    
    var creationDate: Date { get }
    var lastEditDate: Date { get set }
}
