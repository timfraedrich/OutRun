import SwiftUI

struct OptionalDatePicker<Range>: View {
    
    @Binding private var date: Date?
    @State private var showPopover: Bool = false
    
    private let range: Range?
    private let defaultValue: Date
    private let displayedComponents: DatePickerComponents
    private let labelFormatStyle: Date.FormatStyle
    
    private var title: String { date?.formatted(labelFormatStyle) ?? .init(localized: "select") }
    private var dateBinding: Binding<Date> {
        Binding(
            get: { date ?? defaultValue },
            set: { newValue in date = newValue }
        )
    }
    
    var body: some View {
        HStack(spacing: .small) {
            Button(title, action: startSelection)
                .contentTransition(.numericText())
            if date != nil {
                Button("remove", systemImage: "xmark", action: remove)
                    .labelStyle(.iconOnly)
                    .symbolVariant(.circle.fill)
            }
        }
        .animation(.default, value: date)
        .popover(isPresented: $showPopover, attachmentAnchor: .rect(.bounds)) {
            Group {
                let instruction = String(localized: "optional_date_picker_instruction")
                if let range = range as? ClosedRange<Date> {
                    DatePicker(instruction, selection: dateBinding, in: range, displayedComponents: displayedComponents)
                } else if let range = range as? PartialRangeFrom<Date> {
                    DatePicker(instruction, selection: dateBinding, in: range, displayedComponents: displayedComponents)
                } else if let range = range as? PartialRangeThrough<Date> {
                    DatePicker(instruction, selection: dateBinding, in: range, displayedComponents: displayedComponents)
                } else {
                    DatePicker(instruction, selection: dateBinding, displayedComponents: displayedComponents)
                }
            }
            .datePickerStyle(.graphical)
            .frame(width: 300)
            .padding(.small)
            .presentationCompactAdaptation(.popover)
        }
    }
    
    init(
        selection: Binding<Date?>,
        in range: Range? = nil,
        defaultValue: Date = .now,
        displayedComponents: DatePickerComponents = [.date, .hourAndMinute],
        labelFormatStyle: Date.FormatStyle = Date.FormatStyle(date: .abbreviated, time: .shortened)
    ) where Range == ClosedRange<Date> {
        self._date = selection
        self.range = range
        self.defaultValue = defaultValue
        self.displayedComponents = displayedComponents
        self.labelFormatStyle = labelFormatStyle
    }
    
    init(
        selection: Binding<Date?>,
        in range: Range,
        defaultValue: Date = .now,
        displayedComponents: DatePickerComponents = [.date, .hourAndMinute],
        labelFormatStyle: Date.FormatStyle = Date.FormatStyle(date: .abbreviated, time: .shortened)
    ) where Range == PartialRangeFrom<Date> {
        self._date = selection
        self.range = range
        self.defaultValue = defaultValue
        self.displayedComponents = displayedComponents
        self.labelFormatStyle = labelFormatStyle
    }
    
    init(
        selection: Binding<Date?>,
        in range: Range,
        defaultValue: Date = .now,
        displayedComponents: DatePickerComponents = [.date, .hourAndMinute],
        labelFormatStyle: Date.FormatStyle = Date.FormatStyle(date: .abbreviated, time: .shortened)
    ) where Range == PartialRangeThrough<Date> {
        self._date = selection
        self.range = range
        self.defaultValue = defaultValue
        self.displayedComponents = displayedComponents
        self.labelFormatStyle = labelFormatStyle
    }
    
    private func startSelection() {
        showPopover = true
        guard date == nil else { return }
        date = dateBinding.wrappedValue
    }
    
    private func remove() {
        date = nil
    }
}

#Preview {
    OptionalDatePicker(selection: .constant(.now))
}
