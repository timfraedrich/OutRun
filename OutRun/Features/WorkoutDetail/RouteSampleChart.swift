import Charts
import OutRunCore
import SwiftUI

struct RouteSampleChart<Value: Plottable>: View {
    
    private let series: [Series]
    private let dateRange: ClosedRange<Date>
    private let axisValues: [Date]
    
    var body: some View {
        Chart(series) { series in
            ForEach(series.items) { item in
                LineMark(x: .value("Timestamp", item.timestamp), y: .value("", item.value))
                    .foregroundStyle(by: .value("Series", series.id.uuidString))
                    .zIndex(series.active ? 1 : 0)
            }
        }
        .chartLegend(.hidden)
        .chartForegroundStyleScale { (plottable: String) in
            if let id = UUID(uuidString: plottable), series.first(where: { $0.id == id })?.active == true {
                AnyShapeStyle(.tint)
            } else {
                AnyShapeStyle(.gray)
            }
        }
        .chartXScale(domain: dateRange)
        .chartXAxis {
            AxisMarks(values: axisValues) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
    }
    
    init(
        sectionedSamples: CategorizedArray<Bool, any WorkoutRouteDataSampleProtocol>,
        valueKeyPath: KeyPath<any WorkoutRouteDataSampleProtocol, Value>,
        dateRange: ClosedRange<Date>
    ) {
        self.series = sectionedSamples.map { active, samples in
            .init(active: active, items: samples.map { .init(timestamp: $0.timestamp, value: $0[keyPath: valueKeyPath]) })
        }
        self.dateRange = dateRange
        self.axisValues = DateBins(range: dateRange, desiredCount: 6).thresholds.dropLast(1)
    }
    
    init(samples: [any WorkoutRouteDataSampleProtocol], valueKeyPath: KeyPath<any WorkoutRouteDataSampleProtocol, Value>, dateRange: ClosedRange<Date>) {
        self.init(sectionedSamples: [(true, samples)], valueKeyPath: valueKeyPath, dateRange: dateRange)
    }
    
    private struct Series: Identifiable {
        let id = UUID()
        let active: Bool
        let items: [Item]
    }
    
    private struct Item: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: Value
    }
}
