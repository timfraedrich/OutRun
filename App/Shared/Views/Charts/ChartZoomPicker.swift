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

import SwiftUI

/// - note: Hidden when the duration is too short to offer any level besides the whole duration.
struct ChartZoomPicker: View {
    
    @Binding var selection: ChartZoomLevel
    let duration: TimeInterval
    
    private var levels: [ChartZoomLevel] { ChartZoomLevel.levels(for: duration) }
    
    var body: some View {
        if levels.count > 1 {
            Picker("chart_zoom", selection: $selection) {
                ForEach(levels) { level in
                    switch level {
                    case .whole:
                        Text("chart_zoom_whole").tag(level)
                    case .span(let length):
                        Text(Duration.seconds(length), format: .units(allowed: [.hours, .minutes], width: .abbreviated)).tag(level)
                    }
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .onChange(of: levels) { _, newLevels in
                if !newLevels.contains(selection) {
                    selection = .whole
                }
            }
        }
    }
}
