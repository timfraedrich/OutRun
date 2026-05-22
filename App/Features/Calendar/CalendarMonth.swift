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
