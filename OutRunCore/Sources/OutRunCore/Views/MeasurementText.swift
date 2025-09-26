import SwiftUI

public struct MeasurementText<U: Dimension, R: RangeExpression<Int>>: View {
    
    @Environment(\.locale) private var locale
    private let measurement: Measurement<U>
    private let unit: U
    private let fractionLength: R
    
    private var text: String {
        Measurement<U>.FormatStyle.measurement(
            width: .abbreviated,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(fractionLength))
        )
        .locale(locale)
        .format(measurement.converted(to: unit))
    }
    
    public var body: some View {
        Text(text)
    }
    
    public init(_ measurement: Measurement<U>, unit: U, fractionLength: R) {
        self.measurement = measurement
        self.unit = unit
        self.fractionLength = fractionLength
    }
    
    public init(_ measurement: Measurement<U>, unit: U, fractionLength: R = 0...2) where R == ClosedRange<Int> {
        self.measurement = measurement
        self.unit = unit
        self.fractionLength = fractionLength
    }
}
