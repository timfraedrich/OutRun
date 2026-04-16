import SwiftUI

/// A container for attaching a label to a WorkoutMetricText view.
public struct WorkoutMetricLabeledContent<Label: View>: View {
    
    private let label: () -> Label
    private let metricValue: WorkoutMetric.ValueRepresentation
    
    public var body: some View {
        LabeledContent {
            WorkoutMetricText(metricValue: metricValue)
        } label: {
            label()
        }
    }
    
    public init(_ metricValue: WorkoutMetric.ValueRepresentation, @ViewBuilder label: @escaping () -> Label) {
        self.label = label
        self.metricValue = metricValue
    }
    
    public init(_ localizedString: LocalizedStringKey, metricValue: WorkoutMetric.ValueRepresentation) where Label == Text {
        self.init(metricValue) {
            Text(localizedString)
        }
    }
    
    public init(verbatim content: String, metricValue: WorkoutMetric.ValueRepresentation) where Label == Text {
        self.init(metricValue) {
            Text(verbatim: content)
        }
    }
    
    /// This optional initializer tries to get the metric value based on the provided metric and workout.
    /// - note: If no value is available based on the metric and workout this will result in no view being displayed. This initializer
    /// should therefore only be used if a missing metrics not being rendered at all is expected behaviour.
    public init?(_ metric: WorkoutMetric, for workout: any WorkoutProtocol) where Label == Text {
        guard let metricValue = metric.value(for: workout) else { return nil }
        let title: String = if metric == .repetitions, workout.type == .cycling {
            .init(localized: "workout_metric_repetitions_cycle_strokes", bundle: .module)
        } else if metric == .repetitions {
            .init(localized: "workout_metric_repetitions_steps", bundle: .module)
        } else {
            metric.description
        }
        self.init(verbatim: title, metricValue: metricValue)
    }
}

#Preview {
    VStack {
        WorkoutMetricLabeledContent("Type", metricValue: .type(.running))
        WorkoutMetricLabeledContent("Distance", metricValue: .longDistanceMeasurement(.init(value: 4.2 * 1000, unit: .meters)))
        WorkoutMetricLabeledContent("Ascent", metricValue: .shortDistanceMeasurement(.init(value: 42, unit: .meters)))
        WorkoutMetricLabeledContent("Steps", metricValue: .integerValue(42))
        WorkoutMetricLabeledContent("Date", metricValue: .day(.now))
        WorkoutMetricLabeledContent("Start time", metricValue: .timeOfDay(.now))
        WorkoutMetricLabeledContent("Duration", metricValue: .duration(42 * 60 + 42))
        WorkoutMetricLabeledContent("Avg. Speed", metricValue: .speedMeasurement(.init(value: 5.1, unit: .metersPerSecond)))
        WorkoutMetricLabeledContent("Pace", metricValue: .paceMeasurement(.init(value: 14 / 3.6, unit: .metersPerSecond)))
        WorkoutMetricLabeledContent("Energy", metricValue: .energyMeasurement(.init(value: 2300 * 1000, unit: .joules)))
    }
}
