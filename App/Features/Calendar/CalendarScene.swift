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

import OutRunCore
import SwiftData
import SwiftUI
import TFRouting

struct CalendarScene: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(RouterNode.self) private var node
    @Query private var workouts: [Workout]
    
    private var toolbarBackgroundVisibility: Visibility { if #available(iOS 26, *) { .automatic } else { .visible } }
    private var months: [CalendarMonth] {
        let startDate = workouts.first?.startDate ?? .now
        guard let startMonth = CalendarMonth(calendar: calendar, date: startDate) else { return [] }
        var months: [CalendarMonth] = [startMonth]
        if let currentMonth = CalendarMonth(calendar: calendar, date: .now) {
            while let month = months.last?.advanced(by: 1, calendar: calendar), month <= currentMonth {
                months.append(month)
            }
        }
        guard let nextMonth = months.last?.advanced(by: 1, calendar: calendar) else { return months }
        months.append(nextMonth)
        guard months.count < 3, let firstMonth = months.first?.advanced(by: -1, calendar: calendar) else { return months }
        months.insert(firstMonth, at: .zero)
        return months
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: .zero, pinnedViews: .sectionHeaders) {
                ForEach(months) { month in
                    CalendarMonthView(for: month, calendar: calendar) { day, entries in
                        guard !entries.isEmpty else { return }
                        if entries.count == 1, let entry = entries.first {
                            node.route(WorkoutDetailRoute(id: entry.id))
                        } else if let dayStartDate = calendar.date(bySetting: .day, value: day, of: month.range.lowerBound),
                                  let nextDayStartDate = calendar.date(byAdding: .day, value: 1, to: dayStartDate) {
                            node.route(WorkoutSelectionRoute(between: dayStartDate, and: nextDayStartDate))
                        }
                    }
                }
            }
        }
        .background()
        .defaultScrollAnchor(.bottom)
        .safeAreaPadding(.top, .regular)
        .compatibleSafeAreaBar(edge: .top) {
            if #available(iOS 26, *) {
                weekdayHeaderBar
            } else {
                weekdayHeaderBar.background()
            }
        }
        .customBottomSafeAreaBar(content: CalendarLegend.init)
        .toolbar(content: toolbarContent)
        .toolbarBackground(toolbarBackgroundVisibility, for: .navigationBar)
        .navigationTitle("calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private var weekdayHeaderBar: some View {
        LazyVGrid(columns: gridColumns, spacing: 0) {
            ForEach(weekdayLabels, id: \.self) { label in
                Text(label)
                    .lineLimit(1)
                    .font(.caption)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, .regular)
        .padding(.vertical, .extraSmall)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("close", systemImage: "xmark", action: dismiss.callAsFunction)
        }
    }
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    }

    private var weekdayLabels: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let offset = calendar.firstWeekday - 1
        return Array(symbols[offset...] + symbols[..<offset])
    }
    
    init() {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate, order: .forward)]
        )
        descriptor.propertiesToFetch = [\.startDate]
        _workouts = Query(descriptor)
    }
}
