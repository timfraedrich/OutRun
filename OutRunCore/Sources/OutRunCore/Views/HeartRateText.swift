import SwiftUI

public struct HeartRateText: View {
    
    @Environment(\.locale) private var locale
    private let heartRate: UInt8
    
    private var text: String {
        Measurement<UnitFrequency>.FormatStyle.measurement(
            width: .abbreviated,
            usage: .asProvided,
            numberFormatStyle: .number.rounded()
        )
        .locale(locale)
        .format(.init(value: Double(heartRate), unit: UnitFrequency(symbol: .init(localized: "unit_beats_per_minute"))))
    }
    
    public var body: some View {
        Text(text)
    }
    
    public init(_ heartRate: UInt8) {
        self.heartRate = heartRate
    }
}
