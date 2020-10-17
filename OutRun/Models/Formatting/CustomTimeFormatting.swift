//
//  CustomTimeFormatting.swift
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

class CustomTimeFormatting {
    
    static var dayIDFormat = "yyyyMMdd"
    
    static func dayString(forDate date: Date) -> String {
        if date.isSameDay() {
            return LS["Today"]
        } else if date.isYesterday() {
            return LS["Yesterday"]
        }
        let dateFormatter = DateFormatter()
        
        if date.isLessThanAWeekAway() {
            dateFormatter.dateFormat = "EEEE"
            return dateFormatter.string(from: date)
        }
        
        dateFormatter.doesRelativeDateFormatting = true
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
    
    static func dayString(forIdentifier dayIdentifier: String) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dayIDFormat
        guard let date = dateFormatter.date(from: dayIdentifier) else {
            return nil
        }
        return dayString(forDate: date)
    }
    
    static func dayIdentifier(forDate date: Date) -> String {
        string(for: dayIDFormat, date: date)
    }
    
    static func timeString(forDate date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = .none
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    static func backupTimeCode(forDate date: Date) -> String {
        return string(for: "yyyyMMdd-HHmmss", date: date)
    }
    
    static func fullDateString(forDate date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    private static func string(for dateFormat: String, date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
    
}
