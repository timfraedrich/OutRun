import OutRunCore
import SwiftData
import SwiftUI

struct CalendarMonthView: View {
    
    typealias Action = (_ day: Int, _ entries: [CalendarDayEntry]) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @State private var gridCells: [GridCell]
    let month: CalendarMonth
    let action: Action

    var body: some View {
        Section {
            dayGrid
        } header: {
            monthHeaderView
        }
        .task {
            do {
                let range = month.range
                var descriptor = FetchDescriptor<Workout>(
                    predicate: #Predicate { $0.startDate >= range.lowerBound && $0.startDate < range.upperBound },
                    sortBy: [SortDescriptor(\.startDate, order: .forward)]
                )
                descriptor.propertiesToFetch = [\.id, \.startDate, \.rawType]
                let workouts = try modelContext.fetch(descriptor)
                var workoutIndex: Int = .zero
                var gridCells = gridCells
                for index in gridCells.indices {
                    switch gridCells[index] {
                    case .placeholder: continue
                    case let .day(day, _, isToday):
                        var entries: [CalendarDayEntry] = []
                        while let workout = workouts[safeIndex: workoutIndex], calendar.component(.day, from: workout.startDate) == day {
                            entries.append(.init(id: workout.id, type: workout.type))
                            workoutIndex += 1
                        }
                        gridCells[index] = .day(number: day, entries: entries, isToday: isToday)
                    }
                }
                self.gridCells = gridCells
            } catch {}
        }
    }

    @ViewBuilder private var monthHeaderView: some View {
        Text(monthTitle)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.vertical, .extraSmall)
            .padding(.horizontal, .regular)
            .background { Rectangle().fill(.background).mask { EllipticalGradient(colors: [.black, .clear]) } }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var dayGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: .extraSmall) {
            ForEach(Array(gridCells.enumerated()), id: \.offset) { _, cell in
                switch cell {
                case .placeholder:
                    Color.clear.frame(height: 44)
                case .day(let day, let entries, let isToday):
                    CalendarDayCell(
                        day: day,
                        entries: entries,
                        isToday: isToday,
                        action: { action(day, entries) }
                    )
                    .frame(height: 44)
                }
            }
        }
        .padding(.horizontal, .regular)
        .padding(.bottom, .regular)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = locale
        formatter.calendar = calendar
        return formatter.string(from: month.range.lowerBound)
    }
    
    init(for month: CalendarMonth, calendar: Calendar, action: @escaping Action) {
        self.month = month
        self.action = action
        let firstDayDate = month.range.lowerBound
        let firstWeekday = calendar.firstWeekday
        let firstDayWeekday = calendar.component(.weekday, from: firstDayDate)
        let offset = (firstDayWeekday - firstWeekday + 7) % 7
        var cells: [GridCell] = Array(repeating: .placeholder, count: offset)
        if let dayRange = calendar.range(of: .day, in: .month, for: firstDayDate) {
            let now = Date.now
            let today: Int? = if calendar.isDate(firstDayDate, equalTo: now, toGranularity: .month) {
                calendar.component(.day, from: now)
            } else {
                .none
            }
            for day in dayRange {
                cells.append(.day(number: day, entries: [], isToday: day == today))
            }
        }
        self.gridCells = cells
    }
    
    private enum GridCell {
        case placeholder
        case day(number: Int, entries: [CalendarDayEntry], isToday: Bool)
    }
}
