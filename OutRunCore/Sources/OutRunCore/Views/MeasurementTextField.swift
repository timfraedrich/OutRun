import SwiftUI

public struct MeasurementTextField<U: Dimension, R: RangeExpression<Int>>: View {
    
    @Environment(\.locale) private var locale
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
            TextField("Your weight", value: valueBinding, format: .number)
            Text(formattedUnit)
        }
    }
    
    public init(_ measurement: Binding<Measurement<U>?>, unit: U, fractionLength: R) {
        self._measurement = measurement
        self.unit = unit
        self.fractionLength = fractionLength
    }
    
    public init(_ measurement: Binding<Measurement<U>?>, unit: U, fractionLength: R = 0...2) where R == ClosedRange<Int> {
        self._measurement = measurement
        self.unit = unit
        self.fractionLength = fractionLength
    }
}
