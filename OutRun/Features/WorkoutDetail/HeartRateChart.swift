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
            switch item {
            case .range(let range):
                BarMark(
                    x: .value("Timestamp", range.midTimestamp),
                    yStart: .value("Min BPM", range.valueRange.lowerBound),
                    yEnd: .value("Max BPM", range.valueRange.upperBound),
                    width: .inset(2)
                )
                .clipShape(.capsule)
                .accessibilityValue(Text("\(range.valueRange.lowerBound) to \(range.valueRange.upperBound) BPM"))
            case .sample(let sample):
                BarMark(
                    x: .value("Timestamp", sample.timestamp),
                    yStart: .value("BPM", sample.value + 8),
                    yEnd: .value("BPM", sample.value - 8),
                    width: .inset(2)
                )
                .clipShape(.circle)
                .accessibilityValue(Text("\(sample.value) BPM"))
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
    
    init(samples: [any WorkoutHeartRateDataSampleProtocol], dateRange: ClosedRange<Date>) {
        let bins = DateBins(range: dateRange, desiredCount: 60)
        var groups: [Int: [any WorkoutHeartRateDataSampleProtocol]] = [:]
        var minValue = UInt8.max, maxValue = UInt8.min
        for sample in samples {
            minValue = min(minValue, sample.heartRate)
            maxValue = max(maxValue, sample.heartRate)
            let binIndex = bins.index(for: sample.timestamp)
            guard bins.indices.contains(binIndex) else { continue }
            groups[binIndex, default: []].append(sample)
        }
        var items: [Item] = []
        for (index, groupSamples) in groups {
            guard bins.indices.contains(index) else { continue }
            var minGroupValue = UInt8.max, maxGroupValue = UInt8.min
            for groupSample in groupSamples {
                minGroupValue = min(minGroupValue, groupSample.heartRate)
                maxGroupValue = max(maxGroupValue, groupSample.heartRate)
            }
            let item: Item
            if minGroupValue == maxGroupValue, let sample = groupSamples.first {
                item = .sample(.init(timestamp: sample.timestamp, value: sample.heartRate))
            } else {
                let timestampRange = bins.thresholds[index]...bins.thresholds[index + 1]
                let valueRange = minGroupValue...maxGroupValue
                item = .range(.init(timestampRange: timestampRange, valueRange: valueRange))
            }
            items.append(item)
        }
        var axisValues: [Date] = []
        for (index, threshold) in bins.thresholds.enumerated() where index.isMultiple(of: 10) {
            axisValues.append(threshold)
        }
        self.dateRange = dateRange
        minValue -= 10 + minValue % 10
        maxValue += 19 - maxValue % 10
        self.minValue = minValue
        self.maxValue = maxValue
        self.items = items
        self.axisValues = axisValues
    }
    
    private enum Item: Identifiable {
        case sample(IdentifiableSample)
        case range(IdentifiableSampleRange)
        
        var id: UUID {
            switch self {
            case .sample(let sample): sample.id
            case .range(let range): range.id
            }
        }
    }
    
    private struct IdentifiableSampleRange: Identifiable {
        let id = UUID()
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
    
    private struct IdentifiableSample: Identifiable {
        let id = UUID()
        let timestamp: Date
        let value: UInt8
        
        init(timestamp: Date, value: UInt8) {
            self.timestamp = timestamp
            self.value = value
        }
    }
}
