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
import OutRunCore


struct SetupProfileDraft {
    
    var name: String = ""
    var birthdate: Date?
    var weight: Measurement<UnitMass>?
    var sex: Sex?
    
    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    var isComplete: Bool { !trimmedName.isEmpty }
    var birthday: Day? { birthdate.map(Day.init) }
    var weightInKilograms: Double? { weight?.converted(to: .kilograms).value }
    
    init() {}
    
    init(from user: any UserProtocol) {
        name = user.name
        birthdate = try? user.birthday?.date()
        weight = user.weight.map { Measurement(value: $0, unit: .kilograms) }
        sex = user.sex
    }
}
