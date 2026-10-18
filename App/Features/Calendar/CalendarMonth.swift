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

struct CalendarMonth: Identifiable, Comparable {
    
    var id: Date { range.lowerBound }
    let range: Range<Date>
    
    init?(calendar: Calendar, date: Date) {
        let components = calendar.dateComponents([.month, .year], from: date)
        guard let startDate = calendar.date(from: components), let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)
        else { return nil }
        self.range = startDate..<endDate
    }
    
    func distance(to other: CalendarMonth, calendar: Calendar) -> Int {
        calendar.dateComponents([.month], from: range.lowerBound, to: other.range.lowerBound).month ?? .zero
    }
    
    func advanced(by n: Int, calendar: Calendar) -> CalendarMonth {
        guard let date = calendar.date(byAdding: .month, value: n, to: range.lowerBound),
              let month = CalendarMonth(calendar: calendar, date: date)
        else { return self }
        return month
    }
    
    static func < (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        lhs.range.lowerBound < rhs.range.lowerBound
    }
}
