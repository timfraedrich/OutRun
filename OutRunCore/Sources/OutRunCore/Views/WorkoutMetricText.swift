import SwiftUI

public struct WorkoutMetricText: View {
    
    @Environment(\.locale) private var locale
    @Environment(UserPreferences.self) private var userPreferences: UserPreferences?
    private let metricValue: WorkoutMetric.ValueRepresentation?
    
    private var longDistanceUnit: UnitLength { userPreferences?.distanceUnit ?? UserPreferences.fallbackDistanceUnit(for: locale) }
    private var generalDistanceUnit: UnitLength { userPreferences?.altitudeUnit ?? UserPreferences.fallbackAltitudeUnit(for: locale) }
    private var energyUnit: UnitEnergy { userPreferences?.energyUnit ?? UserPreferences.fallbackEnergyUnit(for: locale) }
    private var speedUnit: UnitSpeed { userPreferences?.speedUnit ?? UserPreferences.fallbackSpeedUnit(for: locale) }
    
    func format(_ duration: TimeInterval, using allowedUnits: NSCalendar.Unit) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.calendar?.locale = locale
        formatter.allowedUnits = allowedUnits
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        let duration: TimeInterval = if duration.isFinite, !duration.isNaN { duration } else { .zero }
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
            MeasurementText(measurement, unit: longDistanceUnit)
        case .shortDistanceMeasurement(let measurement):
            MeasurementText(measurement, unit: generalDistanceUnit)
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
        case .increasingDuration(let startDate, let offset):
            TimelineView(.animation) { context in
                if let formattedDuration = format(startDate.addingTimeInterval(offset).distance(to: context.date), using: [.hour, .minute, .second]) {
                    Text(formattedDuration)
                }
            }
        case .speedMeasurement(let measurement):
            MeasurementText(measurement, unit: speedUnit)
        case .paceMeasurement(let measurement):
            let duration = longDistanceUnit.converter.baseUnitValue(fromValue: 1) / measurement.converted(to: .metersPerSecond).value
            if let formattedPace = format(duration, using: [.minute, .second]) {
                Text(formattedPace)
            }
        case .energyMeasurement(let measurement):
            MeasurementText(measurement, unit: energyUnit, fractionLength: 0...0)
        case .heartRate(let heartRate):
            HeartRateText(heartRate)
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
        WorkoutMetricText(metricValue: .increasingDuration(.now, -1000))
        WorkoutMetricText(metricValue: .speedMeasurement(.init(value: 5.1, unit: .metersPerSecond)))
        WorkoutMetricText(metricValue: .paceMeasurement(.init(value: 14 / 3.6, unit: .metersPerSecond)))
        WorkoutMetricText(metricValue: .energyMeasurement(.init(value: 2300 * 1000, unit: .joules)))
    }
}
