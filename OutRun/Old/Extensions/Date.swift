//
//  Date.swift
//
//  OutRun
//  Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

extension Date {
    
    func distance(to date: Date) -> TimeInterval {
        return abs(date.timeIntervalSince(self))
    }
    
    func isSameDay(to compareDate: Date = Date()) -> Bool {
        compareDaysOnly(to: compareDate, with: [.year, .month, .day]) == 0
    }
    
    func isYesterday(from compareDate: Date = Date()) -> Bool {
        compareDaysOnly(to: compareDate, with: [.year, .month, .day]) == 24 * 60 * 60
    }
    
    func isLessThanAWeekAway(from compareDate: Date = Date()) -> Bool {
        compareDaysOnly(to: compareDate, with: [.year, .month, .day]) <= 7 * 24 * 60 * 60
    }
    
    private func compareDaysOnly(to compareDate: Date, with includeComponents: [Calendar.Component]) -> TimeInterval {
        let components = asComponents(include:  includeComponents)
        let compareComponents = compareDate.asComponents(include: includeComponents)
        guard let date1 = Calendar.current.date(from: components), let date2 = Calendar.current.date(from: compareComponents) else {
            fatalError("Failed to compare dates")
        }
        return date1 > date2 ? date1.distance(to: date2) : date2.distance(to: date1)
    }
    
    private func asComponents(include components: [Calendar.Component]) -> DateComponents {
        Calendar.current.dateComponents(Set<Calendar.Component>(components), from: self)
    }
    
    private func get(component: Calendar.Component) -> Int {
        Calendar.current.component(component, from: self)
    }
    
}
