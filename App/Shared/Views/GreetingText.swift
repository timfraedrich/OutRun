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

struct GreetingText: View {
    
    private let name: String
    
    init(name: String) {
        self.name = name
    }
    
    var body: some View {
        TimelineView(Schedule()) { context in
            Group {
                Text(greeting(for: context.date) + " ") + Text(name).foregroundStyle(.tint)
            }
            .animation(.default, value: greeting(for: context.date))
        }
    }
    
    private func greeting(for date: Date) -> String {
        return switch Calendar.current.component(.hour, from: date) {
        case 5..<10: .init(localized: "greeting_morning")
        case 10..<12: .init(localized: "greeting_day")
        case 12..<18: .init(localized: "greeting_afternoon")
        case 18..<22: .init(localized: "greeting_evening")
        default: .init(localized: "greeting_night")
        }
    }
    
    private struct Schedule: TimelineSchedule {
        func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
            var current = startDate
            let calendar = Calendar.current
            var isFirstEntry = true
            
            return AnyIterator {
                guard !isFirstEntry else { isFirstEntry = false; return current }
                let hour = calendar.component(.hour, from: current)
                let nextDate: Date = switch hour {
                case ..<5: calendar.date(bySettingHour: 5, minute: 0, second: 0, of: current) ?? current
                case ..<10: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: current) ?? current
                case ..<12: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: current) ?? current
                case ..<18: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: current) ?? current
                case ..<22: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: current) ?? current
                default: calendar.date(
                    bySettingHour: 5, minute: 0, second: 0,
                    of: calendar.date(byAdding: .day, value: 1, to: current) ?? current
                ) ?? current
                }
                guard nextDate > current else { return current.addingTimeInterval(60 * 60) }
                current = nextDate
                return current
            }
        }
    }
}

#Preview {
    GreetingText(name: "John")
}
