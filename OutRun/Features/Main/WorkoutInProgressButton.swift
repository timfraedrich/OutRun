import OutRunCore
import SwiftUI

struct WorkoutInProgressButton: View {
    
    let workoutType: WorkoutType
    let distance: Measurement<UnitLength>
    let duration: DynamicTimeInterval
    let action: () -> Void
    
    var body: some View {
        let button = Button(action: action) {
            HStack(spacing: .small) {
                WorkoutMetricText(metricValue: .type(.running)).bold()
                switch duration {
                case .constant(let timeInterval):
                    WorkoutMetricText(metricValue: .duration(timeInterval))
                case .increasing(let start, let offset):
                    WorkoutMetricText(metricValue: .increasingDuration(start, offset))
                }
                WorkoutMetricText(metricValue: .longDistanceMeasurement(distance))
                Spacer()
                let image = Image(systemName: "chevron.up.circle.fill").font(.title3)
                if #available(iOS 26, *) {
                    image.foregroundStyle(.tint)
                } else {
                    image
                }
            }
        }
        .monospacedDigit()
        .controlSize(.large)
        if #available(iOS 26, *) {
            button.buttonStyle(.glass)
        } else {
            button.buttonStyle(.actionProminent)
        }
    }
}

#Preview {
    WorkoutInProgressButton(
        workoutType: .running,
        distance: .init(value: 2.4, unit: .kilometers),
        duration: .constant(500),
        action: {}
    )
}
