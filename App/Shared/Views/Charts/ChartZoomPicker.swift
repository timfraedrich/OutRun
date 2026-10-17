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
