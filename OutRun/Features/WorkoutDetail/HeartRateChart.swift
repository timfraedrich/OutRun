import Charts
import OutRunCore
import SwiftUI

struct HeartRateChart: View {
    
    private let items: [Item]
    private let dateRange: ClosedRange<Date>
    private let minValue: UInt8
    private let maxValue: UInt8
    private let axisValues: [Date]
    
    var body: some View {
        Chart(items) { item in
            let foregroundStyle = item.active ? AnyShapeStyle(.tint) : AnyShapeStyle(.gray)
            let zIndex: Double = item.active ? 1 : 0
            switch item.type {
            case .range(let range):
                BarMark(
                    x: .value("timestamp", range.midTimestamp),
                    yStart: .value("minimum_beats_per_minute_short", range.valueRange.lowerBound),
                    yEnd: .value("maximum_beats_per_minute_short", range.valueRange.upperBound),
                    width: .inset(2)
                )
                .clipShape(.capsule)
                .accessibilityValue(Text("\(range.valueRange.lowerBound) to \(range.valueRange.upperBound)" + "unit_beats_per_minute"))
                .foregroundStyle(foregroundStyle)
                .zIndex(zIndex)
            case .sample(let sample):
                BarMark(
                    x: .value("timestamp", sample.timestamp),
                    yStart: .value("beats_per_minute_unit", sample.value + 8),
                    yEnd: .value("beats_per_minute_unit", sample.value - 8),
                    width: .inset(2)
                )
                .clipShape(.circle)
                .accessibilityValue(Text(verbatim: sample.value.description + .init(localized: "beats_per_minute_unit")))
                .foregroundStyle(foregroundStyle)
                .zIndex(zIndex)
            }
        }
        .chartXScale(domain: dateRange)
        .chartYScale(domain: minValue...maxValue)
        .chartXAxis {
            AxisMarks(values: axisValues) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
    }
    
    init(sectionedSamples: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>, dateRange: ClosedRange<Date>) {
        let bins = DateBins(range: dateRange, desiredCount: 60)
        var axisValues: [Date] = []
        for (index, threshold) in bins.thresholds.enumerated() where index.isMultiple(of: 10) {
            axisValues.append(threshold)
        }
        self.dateRange = dateRange
        self.axisValues = axisValues
        guard !sectionedSamples.flatMap(\.elements).isEmpty else {
            self.minValue = .min
            self.maxValue = .max
            self.items = []
            return
        }
        var activeGroups: [Int: [any WorkoutHeartRateDataSampleProtocol]] = [:]
        var inactiveGroups: [Int: [any WorkoutHeartRateDataSampleProtocol]] = [:]
        var minValue = UInt8.max, maxValue = UInt8.min
        for (category, samples) in sectionedSamples {
            for sample in samples {
                minValue = min(minValue, sample.heartRate)
                maxValue = max(maxValue, sample.heartRate)
                let binIndex = bins.index(for: sample.timestamp)
                guard bins.indices.contains(binIndex) else { continue }
                if category {
                    activeGroups[binIndex, default: []].append(sample)
                } else {
                    inactiveGroups[binIndex, default: []].append(sample)
                }
            }
        }
        let activeItems = Self.itemize(groups: activeGroups, bins: bins).map { Item(active: true, type: $0) }
        let inactiveItems = Self.itemize(groups: inactiveGroups, bins: bins).map { Item(active: false, type: $0) }
        minValue -= 10 + minValue % 10
        maxValue += 19 - maxValue % 10
        self.minValue = minValue
        self.maxValue = maxValue
        self.items = activeItems + inactiveItems
    }
    
    init(samples: [any WorkoutHeartRateDataSampleProtocol], dateRange: ClosedRange<Date>) {
        self.init(sectionedSamples: [(true, samples)], dateRange: dateRange)
    }
    
    private static func itemize(groups: [Int: [any WorkoutHeartRateDataSampleProtocol]], bins: DateBins) -> [ItemType] {
        var items: [ItemType] = []
        for (index, groupSamples) in groups {
            var minGroupValue = UInt8.max, maxGroupValue = UInt8.min
            for groupSample in groupSamples {
                minGroupValue = min(minGroupValue, groupSample.heartRate)
                maxGroupValue = max(maxGroupValue, groupSample.heartRate)
            }
            let item: ItemType
            let timestampRange = bins.thresholds[index]...bins.thresholds[index + 1]
            if minGroupValue == maxGroupValue, let sample = groupSamples.first {
                let timestamp = timestampRange.lowerBound.addingTimeInterval(timestampRange.lowerBound.distance(to: timestampRange.upperBound) / 2)
                item = .sample(.init(timestamp: timestamp, value: sample.heartRate))
            } else {
                let valueRange = minGroupValue...maxGroupValue
                item = .range(.init(timestampRange: timestampRange, valueRange: valueRange))
            }
            items.append(item)
        }
        return items
    }
    
    private struct Item: Identifiable {
        let id = UUID()
        let active: Bool
        let type: ItemType
    }
    
    private enum ItemType {
        case sample(Sample)
        case range(SampleRange)
    }
    
    private struct SampleRange {
        let timestampRange: ClosedRange<Date>
        let valueRange: ClosedRange<UInt8>
        
        var midTimestamp: Date {
            timestampRange.lowerBound.addingTimeInterval(timestampRange.lowerBound.distance(to: timestampRange.upperBound) / 2)
        }
        
        init(timestampRange: ClosedRange<Date>, valueRange: ClosedRange<UInt8>) {
            self.timestampRange = timestampRange
            self.valueRange = valueRange
        }
    }
    
    private struct Sample {
        let timestamp: Date
        let value: UInt8
        
        init(timestamp: Date, value: UInt8) {
            self.timestamp = timestamp
            self.value = value
        }
    }
}
