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

import SwiftUI

public struct RelativeDayDateText: View {
    
    private let date: Date
    private var schedule: some TimelineSchedule { DayTimelineSchedule() }
    
    public var body: some View {
        TimelineView(schedule) { context in
            Text(formattedDate(for: context.date))
        }
    }
    
    private func formattedDate(for now: Date) -> String {
        let calendar = Calendar.current
        let fallbackValue = date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits))
        guard let oneDayPrior = calendar.date(byAdding: .day, value: -1, to: now),
              let oneDayAfter = calendar.date(byAdding: .day, value: 1, to: now),
              let oneWeekPrior = calendar.date(byAdding: .weekOfYear, value: -1, to: now)
        else { return fallbackValue }
        let startOfDayToday = calendar.startOfDay(for: now)
        let startOfDayYesterday = calendar.startOfDay(for: oneDayPrior)
        let startOfDayTomorrow = calendar.startOfDay(for: oneDayAfter)
        let startOfDayOneWeekAgo = calendar.startOfDay(for: oneWeekPrior)
        return switch date {
        case startOfDayToday..<startOfDayTomorrow: .init(localized: "date_today", bundle: .module)
        case startOfDayYesterday..<startOfDayToday: .init(localized: "date_yesterday", bundle: .module)
        case startOfDayOneWeekAgo..<startOfDayYesterday: date.formatted(.dateTime.weekday(.wide))
        default: fallbackValue
        }
    }
    
    public init(_ date: Date) {
        self.date = date
    }
}

private struct DayTimelineSchedule: TimelineSchedule {
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        let calendar = Calendar.current
        var current = startDate
        var isFirstEntry = true
        return AnyIterator {
            if isFirstEntry {
                isFirstEntry = false
                return current
            }
            var nextDate = calendar.date(byAdding: .day, value: 1, to: current) ?? current
            nextDate = calendar.startOfDay(for: nextDate)
            current = nextDate
            return current
        }
    }
}
