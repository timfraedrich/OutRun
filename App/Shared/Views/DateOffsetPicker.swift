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

struct DateOffsetPicker: View {
    
    @State private var showPopover = false
    @Binding private var date: Date
    private let startDate: Date
    private let endDate: Date
    private let canSelectEndDate: Bool
    
    /// - note: If `canSelectEndDate` is set to true one second will be added to the pickers. If this last second is selected `date` will be
    /// set to `endDate`.
    init(selection date: Binding<Date>, startDate: Date, endDate: Date, canSelectEndDate: Bool = true) {
        self._date = date
        self.startDate = startDate
        self.endDate = endDate
        self.canSelectEndDate = canSelectEndDate
    }
    
    private var maxOffset: TimeInterval { startDate.distance(to: endDate) }
    private var offset: TimeInterval { min(max(startDate.distance(to: date), 0), maxOffset) }
    /// This property accounts for the additional second added if `canSelectEndDate` is set to true.
    private var maxSelectionOffset: TimeInterval { canSelectEndDate ? maxOffset.rounded(.up) : maxOffset }
    private var hours: Int { offset == maxOffset ? maxHours : Int(offset) / 3600 }
    private var minutes: Int { offset == maxOffset ? maxMinutes : (Int(offset) % 3600) / 60 }
    private var seconds: Int { offset == maxOffset ? maxSeconds : Int(offset) % 60 }
    private var maxHours: Int { Int(maxSelectionOffset) / 3600 }
    private var maxMinutes: Int { maxMinutes(for: hours) }
    private var maxSeconds: Int { maxSeconds(for: hours, and: minutes) }

    private func maxMinutes(for hours: Int) -> Int {
        hours < maxHours ? 59 : (Int(maxSelectionOffset) % 3600) / 60
    }
    
    private func maxSeconds(for hours: Int, and minutes: Int) -> Int {
        hours < maxHours || minutes < maxMinutes(for: hours) ? 59 : (Int(maxSelectionOffset) % 60)
    }
    
    var body: some View {
        Button {
            showPopover = true
        } label: {
            Text(verbatim: formattedOffset)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .popover(isPresented: $showPopover, attachmentAnchor: .rect(.bounds)) {
            HStack(spacing: 0) {
                if maxHours > 0 {
                    Picker("date_component_hour", selection: Binding(get: { hours }, set: { apply(hours: $0) })) {
                        ForEach(0...maxHours, id: \.self) {
                            Text(verbatim: String($0)).tag($0)
                        }
                    }
                    Text(verbatim: ":").font(.headline)
                }
                Picker("date_component_minute", selection: Binding(get: { minutes }, set: { apply(minutes: $0) })) {
                    ForEach(0...maxMinutes, id: \.self, content: label)
                }
                Text(verbatim: ":").font(.headline)
                Picker("date_component_second", selection: Binding(get: { seconds }, set: { apply(seconds: $0) })) {
                    ForEach(0...maxSeconds, id: \.self, content: label)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(width: maxHours > 0 ? 270 : 190)
            .padding(.small)
            .presentationCompactAdaptation(.popover)
        }
    }
    
    @ViewBuilder
    private func label(for value: Int) -> some View {
        Text(verbatim: paddedInteger(value)).tag(value)
    }
    
    private func paddedInteger(_ value: Int) -> String {
        value.formatted(.number.precision(.integerLength(2)))
    }
    
    private var formattedOffset: String {
        let total = Int(offset)
        let hours = total / 3600, minutes = (total % 3600) / 60, seconds = total % 60
        var result = ""
        if hours > 0 { result += "\(hours):" }
        result += "\(paddedInteger(minutes)):\(paddedInteger(seconds))"
        return result
    }
    
    private func apply(hours: Int? = nil, minutes: Int? = nil, seconds: Int? = nil) {
        let hours = min(max(hours ?? self.hours, .zero), maxHours)
        let maxMinutes = maxMinutes(for: hours)
        let minutes = min(max(minutes ?? self.minutes, .zero), maxMinutes)
        let maxSeconds = maxSeconds(for: hours, and: minutes)
        let seconds = min(max(seconds ?? self.seconds, .zero), maxSeconds)
        let newOffset = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        let newDate = startDate.addingTimeInterval(newOffset)
        date = max(startDate, min(endDate, newDate))
    }
}
