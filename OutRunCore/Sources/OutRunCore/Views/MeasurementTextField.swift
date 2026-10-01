import SwiftUI

public struct MeasurementTextField<Label: View, U: Dimension, R: RangeExpression<Int>>: View {
    
    @Environment(\.locale) private var locale
    private let label: () -> Label
    @Binding private var measurement: Measurement<U>?
    private let unit: U
    private let fractionLength: R
    
    private var valueBinding: Binding<Double?> {
        .init {
            measurement?.converted(to: unit).value
        } set: { newValue in
            measurement = if let newValue { .init(value: newValue, unit: unit) } else { nil }
        }
    }
    
    private var formattedUnit: String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.locale = locale
        return formatter.string(from: unit)
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            TextField(value: valueBinding, format: .number.precision(.fractionLength(fractionLength)), label: label)
                .keyboardType(.decimalPad)
            Text(formattedUnit)
        }
    }
    
    public init(_ measurement: Binding<Measurement<U>?>, unit: U, fractionLength: R, @ViewBuilder label: @escaping () -> Label) {
        self.label = label
        self._measurement = measurement
        self.unit = unit
        self.fractionLength = fractionLength
    }
    
    public init(
        _ measurement: Binding<Measurement<U>?>,
        unit: U,
        fractionLength: ClosedRange<Int> = 0...2,
        @ViewBuilder label: @escaping () -> Label
    ) where R == ClosedRange<Int> {
        self.label = label
        self._measurement = measurement
        self.unit = unit
        self.fractionLength = fractionLength
    }
    
    public init(verbatim title: String, _ measurement: Binding<Measurement<U>?>, unit: U, fractionLength: R) where Label == Text {
        self.init(measurement, unit: unit, fractionLength: fractionLength) { Text(verbatim: title) }
    }
    
    public init(
        verbatim title: String,
        measurement: Binding<Measurement<U>?>,
        unit: U,
        fractionLength: ClosedRange<Int> = 0...2
    ) where Label == Text, R == ClosedRange<Int> {
        self.init(measurement, unit: unit, fractionLength: fractionLength) { Text(verbatim: title) }
    }
    
    public init(_ key: LocalizedStringKey, measurement: Binding<Measurement<U>?>, unit: U, fractionLength: R) where Label == Text {
        self.init(measurement, unit: unit, fractionLength: fractionLength) { Text(key) }
    }
    
    public init(
        _ key: LocalizedStringKey,
        measurement: Binding<Measurement<U>?>,
        unit: U,
        fractionLength: ClosedRange<Int> = 0...2
    ) where Label == Text, R == ClosedRange<Int> {
        self.init(measurement, unit: unit, fractionLength: fractionLength) { Text(key) }
    }
}
