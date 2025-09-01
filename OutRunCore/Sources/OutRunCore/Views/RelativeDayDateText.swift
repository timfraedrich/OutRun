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
        case startOfDayToday..<startOfDayTomorrow: R.string.localizable.date_today()
        case startOfDayYesterday..<startOfDayToday: R.string.localizable.date_yesterday()
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
