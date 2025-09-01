import SwiftUI

// TODO: Use preferred units based on user settings in core.
public struct WorkoutMetricText: View {
    
    @Environment(\.locale) private var locale
    private let metricValue: WorkoutMetric.ValueRepresentation?
    
    private var longDistanceUnit: UnitLength { .init(forLocale: locale, usage: .road) }
    private var generalDistanceUnit: UnitLength { .init(forLocale: locale, usage: .general) }
    private var energyUnit: UnitEnergy { .init(forLocale: locale, usage: .workout) }
    private var speedUnit: UnitSpeed { .init(forLocale: locale, usage: .general) }
    
    private func standardMeasurementFormat<U: Dimension, R: RangeExpression<Int>>(
        _ unit: U.Type = U.self,
        fractionLength: R = 0...2
    ) -> Measurement<U>.FormatStyle {
        .measurement(
            width: .abbreviated,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(fractionLength))
        )
        .locale(locale)
    }
    
    func format(_ duration: TimeInterval, using allowedUnits: NSCalendar.Unit) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.calendar?.locale = locale
        formatter.allowedUnits = allowedUnits
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        var formattedDuration = formatter.string(from: duration)
        if formattedDuration?.hasPrefix("0") ?? false {
            formattedDuration?.removeFirst()
        }
        return formattedDuration
    }
    
    public var body: some View {
        switch metricValue {
        case .type(let type):
            Text(type.description)
        case .longDistanceMeasurement(let measurement):
            Text(measurement.converted(to: longDistanceUnit), format: standardMeasurementFormat(UnitLength.self))
        case .shortDistanceMeasurement(let measurement):
            Text(measurement.converted(to: generalDistanceUnit), format: standardMeasurementFormat(UnitLength.self))
        case .integerValue(let value):
            Text(value, format: .number)
        case .day(let date):
            RelativeDayDateText(date)
        case .timeOfDay(let date):
            Text(date, format: .dateTime.hour().minute())
        case .duration(let duration):
            if let formattedDuration = format(duration, using: [.hour, .minute, .second]) {
                Text(formattedDuration)
            }
        case .speedMeasurement(let measurement):
            Text(measurement.converted(to: speedUnit), format: standardMeasurementFormat(UnitSpeed.self))
        case .paceMeasurement(let measurement):
            let duration = longDistanceUnit.converter.baseUnitValue(fromValue: 1) / measurement.converted(to: .metersPerSecond).value
            if let formattedPace = format(duration, using: [.minute, .second]) {
                Text(formattedPace)
            }
        case .energyMeasurement(let measurement):
            Text(measurement.converted(to: energyUnit), format: standardMeasurementFormat(UnitEnergy.self, fractionLength: 0...0))
        case .none:
            EmptyView()
        }
    }
    
    public init(metricValue: WorkoutMetric.ValueRepresentation) {
        self.metricValue = metricValue
    }
}

#Preview {
    VStack {
        WorkoutMetricText(metricValue: .type(.running))
        WorkoutMetricText(metricValue: .longDistanceMeasurement(.init(value: 4.2 * 1000, unit: .meters)))
        WorkoutMetricText(metricValue: .shortDistanceMeasurement(.init(value: 42, unit: .meters)))
        WorkoutMetricText(metricValue: .integerValue(42))
        WorkoutMetricText(metricValue: .day(.now))
        WorkoutMetricText(metricValue: .timeOfDay(.now))
        WorkoutMetricText(metricValue: .duration(42 * 60 + 42))
        WorkoutMetricText(metricValue: .speedMeasurement(.init(value: 5.1, unit: .metersPerSecond)))
        WorkoutMetricText(metricValue: .paceMeasurement(.init(value: 14 / 3.6, unit: .metersPerSecond)))
        WorkoutMetricText(metricValue: .energyMeasurement(.init(value: 2300 * 1000, unit: .joules)))
    }
}
