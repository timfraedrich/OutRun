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

public enum Sex: String, CaseIterable, Codable, CustomDebugStringConvertible, CustomStringConvertible, Hashable, Sendable {
    
    case male
    case female
    
    public var description: String {
        switch self {
        case .male: .init(localized: "sex_male", bundle: .module)
        case .female: .init(localized: "sex_female", bundle: .module)
        }
    }
    
    public var debugDescription: String {
        switch self {
        case .male: "Sex.male"
        case .female: "Sex.female"
        }
    }
}
