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

struct ExactDatePicker<R: RangeExpression<Date>, Label: View>: View {
    
    @Environment(\.calendar) private var calendar
    @Binding private var date: Date
    @State private var showDayPicker: Bool = false
    @State private var showTimePicker: Bool = false
    private let range: R?
    private let label: (() -> Label)?
    
    private var dayDateBinding: Binding<Date> {
        .init {
            date
        } set: { newDayDate in
            let dateComponents = calendar.dateComponents([.second], from: date)
            guard let second = dateComponents.second,
                  let newDate = calendar.date(bySetting: .second, value: second, of: newDayDate),
                  range?.contains(newDate) ?? true
            else { date = newDayDate; return }
            date = newDate
        }
    }
    
    private init(selection: Binding<Date>, label: (() -> Label)?) where R == Range<Date> {
        _date = selection
        range = .none
        self.label = label
    }
    
    private init(selection: Binding<Date>, in range: R?, label: (() -> Label)?) {
        _date = selection
        self.range = range
        self.label = label
    }
    
    init(selection: Binding<Date>) where Label == EmptyView, R == Range<Date> {
        self.init(selection: selection, label: nil)
    }
    
    init(selection: Binding<Date>, in range: R?) where Label == EmptyView {
        self.init(selection: selection, in: range, label: nil)
    }
    
    init(selection: Binding<Date>, @ViewBuilder label: @escaping () -> Label) where R == Range<Date> {
        self.init(selection: selection, label: label as (() -> Label)?)
    }
    
    init(selection: Binding<Date>, in range: R?, @ViewBuilder label: @escaping () -> Label) {
        self.init(selection: selection, in: range, label: label as (() -> Label)?)
    }
    
    init(_ titleKey: LocalizedStringKey, selection: Binding<Date>) where Label == Text, R == Range<Date> {
        self.init(selection: selection) { Text(titleKey) }
    }
    
    init(_ titleKey: LocalizedStringKey, selection: Binding<Date>, in range: R?) where Label == Text {
        self.init(selection: selection, in: range) { Text(titleKey) }
    }
    
    init(_ title: String, selection: Binding<Date>) where Label == Text, R == Range<Date> {
        self.init(selection: selection) { Text(verbatim: title) }
    }
    
    init(_ title: String, selection: Binding<Date>, in range: R?) where Label == Text {
        self.init(selection: selection, in: range) { Text(verbatim: title) }
    }
    
    var body: some View {
        if let label {
            LabeledContent(content: content, label: label)
        } else {
            content()
        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        HStack {
            pickerButton(format: .dateTime.year().month(.defaultDigits).day(), popoverIsPresented: $showDayPicker) {
                Group {
                    let selection = dayDateBinding, components = DatePickerComponents.date, label = EmptyView.init
                    if let range = range as? ClosedRange<Date> {
                        DatePicker(selection: selection, in: range, displayedComponents: components, label: label)
                    } else if let range = range as? PartialRangeFrom<Date> {
                        DatePicker(selection: selection, in: range, displayedComponents: components, label: label)
                    } else if let range = range as? PartialRangeThrough<Date> {
                        DatePicker(selection: selection, in: range, displayedComponents: components, label: label)
                    } else {
                        DatePicker(selection: selection, displayedComponents: components, label: label)
                    }
                }
                .datePickerStyle(.graphical)
            }
            pickerButton(format: .dateTime.hour().minute().second(), popoverIsPresented: $showTimePicker) {
                ExactTimePicker(date: $date, in: range)
            }
        }
    }
    
    @ViewBuilder
    private func pickerButton<Picker: View>(
        format: Date.FormatStyle,
        popoverIsPresented: Binding<Bool>,
        @ViewBuilder picker: @escaping () -> Picker
    ) -> some View {
        Button {
            popoverIsPresented.wrappedValue = true
        } label: {
            Text(date, format: format)
                .padding(.horizontal, .regular)
                .padding(.vertical, .small)
                .background(.quinary)
                .clipShape(.capsule)
                .padding(.vertical, -Spacing.small.rawValue)
        }
        .foregroundStyle(.primary)
        .popover(isPresented: popoverIsPresented) {
            picker()
                .frame(width: 300)
                .padding(.small)
                .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    @Previewable @State var date: Date = .now
    ExactDatePicker(selection: $date, in: ...(.now))
}
