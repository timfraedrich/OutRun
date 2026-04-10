import OutRunCore
import SwiftData
import SwiftUI

struct CalendarScene: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.calendar) private var calendar
    @Environment(CalendarRouter.self) private var calendarRouter
    @Query private var workouts: [Workout]
    
    private var toolbarBackgroundVisibility: Visibility { if #available(iOS 26, *) { .automatic } else { .visible } }
    private var months: [CalendarMonth] {
        guard let startDate = workouts.first?.startDate, let startMonth = CalendarMonth(calendar: calendar, date: startDate) else { return [] }
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
        @Bindable var calendarRouter = calendarRouter
        NavigationStack(path: $calendarRouter.path) {
            ScrollView {
                LazyVStack(spacing: .zero, pinnedViews: .sectionHeaders) {
                    ForEach(months) { month in
                        CalendarMonthView(for: month, calendar: calendar) { day, entries in
                            guard !entries.isEmpty else { return }
                            if entries.count == 1, let entry = entries.first {
                                calendarRouter.path.append(CalendarNavigationDestination.workoutDetails(id: entry.id))
                            } else if let dayStartDate = calendar.date(bySetting: .day, value: day, of: month.range.lowerBound),
                                      let nextDayStartDate = calendar.date(byAdding: .day, value: 1, to: dayStartDate) {
                                calendarRouter.path.append(CalendarNavigationDestination.workoutSelection(between: dayStartDate, and: nextDayStartDate))
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
            .toolbar(content: toolbarContent)
            .toolbarBackground(toolbarBackgroundVisibility, for: .navigationBar)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: CalendarNavigationDestination.self) { destination in
                switch destination {
                case let .workoutDetails(id):
                    QueriedWorkoutDetailScene(id: id, addCloseButton: false)
                case let .workoutSelection(start, end):
                    WorkoutSelectionScene(between: start, and: end)
                }
            }
        }
        .onDisappear(perform: calendarRouter.reset)
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
            Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
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
