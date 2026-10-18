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
