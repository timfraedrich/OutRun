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

import SwiftUI

struct ExactTimePicker<R: RangeExpression<Date>>: View {
    
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Binding private var date: Date
    private let range: R?
    
    init(date: Binding<Date>, in range: R?) {
        self._date = date
        self.range = range
    }
    
    init(date: Binding<Date>) where R == PartialRangeFrom<Date> {
        self._date = date
        self.range = .none
    }
    
    // MARK: - Locale
    
    private var uses12HourFormat: Bool { locale.hourCycle == .oneToTwelve || locale.hourCycle == .zeroToEleven }
    
    private enum Period: Hashable {
        case am, pm
    }
    
    // MARK: - Range helpers
    
    private func inRange(_ d: Date) -> Bool {
        range?.contains(d) ?? true
    }
    
    /// True if any second in `[mark, mark + 3600)` is within `range`.
    private func hourIsSelectable(_ mark: Date) -> Bool {
        guard range != nil else { return true }
        if inRange(mark) { return true }
        if inRange(mark.addingTimeInterval(3599)) { return true }
        // Range might lie entirely within this hour; sample once per minute.
        return stride(from: 60, to: 3600, by: 60).contains {
            inRange(mark.addingTimeInterval(TimeInterval($0)))
        }
    }
    
    /// True if any second within minute `m` of `hourMark` is in range.
    private func minuteIsSelectable(hourMark: Date, minute m: Int) -> Bool {
        guard range != nil else { return true }
        let start = hourMark.addingTimeInterval(TimeInterval(m * 60))
        if inRange(start) { return true }
        if inRange(start.addingTimeInterval(59)) { return true }
        // Range might lie entirely within this minute.
        return (1..<59).contains {
            inRange(start.addingTimeInterval(TimeInterval($0)))
        }
    }
    
    /// Build a date from `hourMark + m:s`. If the result falls outside `range`,
    /// snap to the nearest valid second within the same hour.
    private func makeDate(hourMark: Date, minute m: Int, second s: Int) -> Date {
        let candidate = hourMark.addingTimeInterval(TimeInterval(m * 60 + s))
        guard range != nil, !inRange(candidate) else { return candidate }
        let base = m * 60 + s
        for delta in 1...3600 {
            let lo = base - delta, hi = base + delta
            if lo >= 0 {
                let d = hourMark.addingTimeInterval(TimeInterval(lo))
                if inRange(d) { return d }
            }
            if hi < 3600 {
                let d = hourMark.addingTimeInterval(TimeInterval(hi))
                if inRange(d) { return d }
            }
        }
        return candidate
    }
    
    // MARK: - DST-aware hour enumeration
    
    private var allHourMarks: [Date] {
        let start = calendar.startOfDay(for: date)
        guard let nextStart = calendar.date(byAdding: .day, value: 1, to: start) else {
            return [start]
        }
        var marks: [Date] = []
        var cursor = start
        while cursor < nextStart {
            marks.append(cursor)
            guard let newCursor = calendar.date(byAdding: .hour, value: 1, to: cursor) else { break }
            cursor = newCursor
        }
        return marks
    }
    
    private var visibleHourMarks: [Date] {
        let filtered = allHourMarks.filter(hourIsSelectable)
        guard uses12HourFormat else { return filtered }
        return filtered.filter { isAMHour($0) == !isPM }
    }
    
    private func isAMHour(_ mark: Date) -> Bool {
        calendar.component(.hour, from: mark) < 12
    }
    
    private func displayHour(for mark: Date) -> Int {
        let h = calendar.component(.hour, from: mark)
        if !uses12HourFormat { return h }
        let h12 = h % 12
        return h12 == 0 ? 12 : h12
    }
    
    private var currentHourMark: Date {
        allHourMarks.last { $0 <= date } ?? allHourMarks.first ?? date
    }
    
    private var isPM: Bool {
        calendar.component(.hour, from: date) >= 12
    }
    
    // MARK: - Minute / second
    
    private var visibleMinutes: [Int] {
        let r = calendar.range(of: .minute, in: .hour, for: date) ?? 0..<60
        return Array(r).filter {
            minuteIsSelectable(hourMark: currentHourMark, minute: $0)
        }
    }
    
    private var visibleSeconds: [Int] {
        let r = calendar.range(of: .second, in: .minute, for: date) ?? 0..<60
        let m = calendar.component(.minute, from: date)
        let minuteStart = currentHourMark.addingTimeInterval(TimeInterval(m * 60))
        return Array(r).filter {
            inRange(minuteStart.addingTimeInterval(TimeInterval($0)))
        }
    }
    
    // MARK: - Period filter
    
    private var visiblePeriods: [Period] {
        var am = false, pm = false
        for mark in allHourMarks where hourIsSelectable(mark) {
            if isAMHour(mark) { am = true } else { pm = true }
            if am && pm { break }
        }
        var result: [Period] = []
        if am { result.append(.am) }
        if pm { result.append(.pm) }
        return result
    }
    
    // MARK: - Bindings
    
    private var hourBinding: Binding<Date> {
        .init { currentHourMark }
        set: { newMark in
            let m = calendar.component(.minute, from: date)
            let s = calendar.component(.second, from: date)
            date = makeDate(hourMark: newMark, minute: m, second: s)
        }
    }
    
    private var minutesBinding: Binding<Int> {
        .init { calendar.component(.minute, from: date) }
        set: { newMinute in
            let s = calendar.component(.second, from: date)
            date = makeDate(hourMark: currentHourMark, minute: newMinute, second: s)
        }
    }
    
    private var secondsBinding: Binding<Int> {
        .init { calendar.component(.second, from: date) }
        set: { newSecond in
            let m = calendar.component(.minute, from: date)
            date = makeDate(hourMark: currentHourMark, minute: m, second: newSecond)
        }
    }
    
    private var periodBinding: Binding<Period> {
        .init { isPM ? .pm : .am }
        set: { newPeriod in
            let currentH = calendar.component(.hour, from: date)
            let targetH: Int
            switch newPeriod {
            case .am where currentH >= 12: targetH = currentH - 12
            case .pm where currentH < 12:  targetH = currentH + 12
            default: return
            }
            // Try the exact matching hour first; fall back to the nearest
            // selectable hour in the target period if it's out of range.
            let exact = allHourMarks.first {
                calendar.component(.hour, from: $0) == targetH
            }
            let targetMark: Date
            if let exact, hourIsSelectable(exact) {
                targetMark = exact
            } else {
                let candidates = allHourMarks.filter {
                    isAMHour($0) == (newPeriod == .am) && hourIsSelectable($0)
                }
                guard let nearest = candidates.min(by: {
                    abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date))
                }) else { return }
                targetMark = nearest
            }
            let m = calendar.component(.minute, from: date)
            let s = calendar.component(.second, from: date)
            date = makeDate(hourMark: targetMark, minute: m, second: s)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            Picker("date_component_hour", selection: hourBinding) {
                ForEach(visibleHourMarks, id: \.self) { mark in
                    Text(verbatim: String(displayHour(for: mark))).tag(mark)
                }
            }
            Text(verbatim: ":").font(.headline)
            Picker("date_component_minute", selection: minutesBinding) {
                ForEach(visibleMinutes, id: \.self, content: label)
            }
            Text(verbatim: ":").font(.headline)
            Picker("date_component_second", selection: secondsBinding) {
                ForEach(visibleSeconds, id: \.self, content: label)
            }
            if uses12HourFormat {
                Picker("date_component_period", selection: periodBinding) {
                    ForEach(visiblePeriods, id: \.self) { period in
                        Text(verbatim: period == .am ? calendar.amSymbol : calendar.pmSymbol).tag(period)
                    }
                }
            }
        }
        .pickerStyle(.wheel)
        .labelsHidden()
    }
    
    @ViewBuilder
    private func label(for value: Int) -> some View {
        Text(verbatim: value.formatted(.number.precision(.integerLength(2)))).tag(value)
    }
}

#Preview {
    
    // both of these examples are for daylight saving time dates (too check this edge case)
    @Previewable @State var date1: Date = .init(timeIntervalSince1970: 1761444000)
    @Previewable @State var date2: Date = .init(timeIntervalSince1970: 1774746000)
    
    ExactTimePicker(date: $date1)
    ExactTimePicker(date: $date2, in: ...(.init(timeIntervalSince1970: 1774746063)))
        .environment(\.locale, Locale(identifier: "en-US"))
}
