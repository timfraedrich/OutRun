import Charts
import OutRunCore
import SwiftUI

struct SampleChart<Value: Numeric & Comparable & Plottable>: View {
    
    typealias Sample = (timestamp: Date, value: Value)
    
    private let series: [Series]
    private let dateRange: ClosedRange<Date>
    private let axisValues: [Date]
    private let valueLabelKey: LocalizedStringKey
    
    var body: some View {
        Chart(series) { series in
            ForEach(series.items) { item in
                LineMark(x: .value("timestamp", item.timestamp), y: .value(valueLabelKey, item.value))
                    .foregroundStyle(by: .value("series", series.id.uuidString))
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
        _ valueLabelKey: LocalizedStringKey,
        sectionedSamples: CategorizedArray<Bool, Sample>,
        dateRange: ClosedRange<Date>
    ) {
        self.series = sectionedSamples.map { active, samples in
            .init(active: active, items: samples.compactMap { sample in
                let value = sample.value
                guard value >= Value.zero else { return nil }
                return .init(timestamp: sample.timestamp, value: value)
            })
        }
        self.dateRange = dateRange
        self.axisValues = DateBins(range: dateRange, desiredCount: 6).thresholds.dropLast(1)
        self.valueLabelKey = valueLabelKey
    }
    
    init(_ valueLabelKey: LocalizedStringKey, samples: [Sample], dateRange: ClosedRange<Date>) {
        self.init(valueLabelKey, sectionedSamples: [(true, samples)], dateRange: dateRange)
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
