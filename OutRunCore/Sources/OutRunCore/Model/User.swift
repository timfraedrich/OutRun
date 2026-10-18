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
import SwiftData

@Model
public class User: UserProtocol {
    
    @Attribute(.unique, .preserveValueOnDeletion) public var id: UUID?
    public var name: String
    public var rawBirthday: String?
    public var weight: Double?
    public var sex: Sex?
    
    public var preferences: RawPreferences
    
    public private(set) var creationDate: Date
    public var lastEditDate: Date
    
    public var birthday: Day? {
        get { rawBirthday.flatMap(Day.init(rawValue:)) }
        set { rawBirthday = newValue?.rawValue }
    }
    
    public init(
        id: UUID? = nil,
        name: String,
        birthday: Day? = nil,
        weight: Double? = nil,
        sex: Sex? = nil,
        preferences: RawPreferences = [:],
        creationDate: Date,
        lastEditDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.rawBirthday = birthday?.rawValue
        self.weight = weight
        self.sex = sex
        self.preferences = preferences
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate ?? creationDate
    }
    
    public convenience init(from user: any UserProtocol) {
        self.init(
            id: user.id,
            name: user.name,
            birthday: user.birthday,
            weight: user.weight,
            sex: user.sex,
            preferences: user.preferences,
            creationDate: user.creationDate,
            lastEditDate: user.lastEditDate
        )
    }
}
