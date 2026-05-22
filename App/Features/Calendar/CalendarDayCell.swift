import OutRunCore
import SwiftUI

struct CalendarDayCell: View {

    let day: Int
    let entries: [CalendarDayEntry]
    let isToday: Bool
    let action: () -> Void

    private var hasWorkouts: Bool { !entries.isEmpty }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                ZStack {
                    if isToday {
                        Circle().foregroundStyle(.tint)
                    }
                    Text(day.description)
                        .font(.callout)
                        .minimumScaleFactor(0.5)
                        .fontWeight(isToday ? .bold : .regular)
                        .foregroundStyle(isToday ? .white : hasWorkouts ? .primary : .secondary)
                }
                .frame(width: 30, height: 30)

                HStack(spacing: 2) {
                    ForEach(Array(entries.prefix(3).enumerated()), id: \.offset) { _, entry in
                        Circle()
                            .foregroundStyle(entry.type.color)
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
