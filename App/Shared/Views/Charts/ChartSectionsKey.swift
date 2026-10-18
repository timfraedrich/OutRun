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

/// Cheap identity of sectioned chart data, derived from the section boundaries instead of every sample.
struct ChartSectionsKey: Equatable {
    
    private let sections: [Section]
    
    init<Element>(_ sections: CategorizedArray<Bool, Element>, timestamp: (Element) -> Date) {
        self.sections = sections.map { section in
            Section(
                category: section.category,
                count: section.elements.count,
                first: section.elements.first.map(timestamp),
                last: section.elements.last.map(timestamp)
            )
        }
    }
    
    private struct Section: Equatable {
        let category: Bool
        let count: Int
        let first: Date?
        let last: Date?
    }
}
