import Charts
import OutRunCore
import SwiftUI

struct HeartRateChart: View {
    
    @State private var internalSelectedDate: Date?
    @State private var scrollPosition: Date
    @State private var windowStep = 0
    @State private var preparedMemo = ChartMemo<PreparedKey, Prepared>()
    @State private var renderedItemsMemo = ChartMemo<RenderedItemsKey, [Item]>()
    
    private let sectionedSamples: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>
    private let dateRange: ClosedRange<Date>
    private let zoomLevel: ChartZoomLevel
    private let selection: Binding<Date?>?
    private let onTap: (() -> Void)?
    
    private var duration: TimeInterval { max(dateRange.lowerBound.distance(to: dateRange.upperBound), 1) }
    private var visibleLength: TimeInterval { zoomLevel.visibleLength(for: duration) }
    private var isScrollable: Bool { visibleLength < duration }
    private var preparedKey: PreparedKey {
        PreparedKey(dateRange: dateRange, sections: ChartSectionsKey(sectionedSamples, timestamp: \.timestamp), visibleLength: visibleLength)
    }
    /// - note: Derived from the samples once per change of the input data or zoom level instead of on every view update, e.g. while
    ///   scrubbing updates the selection of a parent.
    private var prepared: Prepared {
        preparedMemo.value(for: preparedKey) {
            Prepared(sectionedSamples: sectionedSamples, dateRange: dateRange, visibleLength: visibleLength)
        }
    }
    private var renderedWindow: ClosedRange<Date> {
        guard isScrollable else { return dateRange }
        return ChartWindow(dateRange: dateRange, visibleLength: visibleLength, step: windowStep).range
    }
    /// The items limited to the bins of the rendered window, as Charts gets slow with thousands of marks.
    private var renderedItems: [Item] {
        let window = renderedWindow
        return renderedItemsMemo.value(for: RenderedItemsKey(prepared: preparedKey, window: window)) {
            let prepared = self.prepared
            let bins = prepared.bins.index(for: window.lowerBound) - 1...prepared.bins.index(for: window.upperBound) + 1
            return [prepared.activeItems, prepared.inactiveItems].flatMap { items in
                let lowerIndex = items.binarySearch { $0.binIndex < bins.lowerBound }
                let upperIndex = items.binarySearch { $0.binIndex <= bins.upperBound }
                return items[lowerIndex..<max(upperIndex, lowerIndex)]
            }
        }
    }
    private var selectedDate: Date? {
        get { selection?.wrappedValue ?? internalSelectedDate }
        nonmutating set {
            if let selection {
                selection.wrappedValue = newValue
            } else {
                internalSelectedDate = newValue
            }
        }
    }
    private var selectedDateBinding: Binding<Date?> {
        Binding { selectedDate } set: { selectedDate = $0 }
    }
    private var selectedBinIndex: Int? {
        guard let selectedDate else { return nil }
        let prepared = self.prepared
        let index = prepared.bins.index(for: selectedDate)
        return prepared.binValueRanges[index] == nil ? nil : index
    }
    private var selectedBin: (timestampRange: Range<Date>, valueRange: ClosedRange<UInt8>)? {
        let prepared = self.prepared
        guard let selectedBinIndex, let valueRange = prepared.binValueRanges[selectedBinIndex] else { return nil }
        let bin = prepared.bins[selectedBinIndex]
        return (bin.lowerBound..<bin.upperBound, valueRange)
    }
    
    var body: some View {
        scrollableChart
            .chartXScale(domain: dateRange)
            .chartYScale(domain: prepared.valueRange)
            .chartXAxis {
                AxisMarks(values: ChartTimeAxis.values(in: dateRange, visibleLength: visibleLength, window: renderedWindow)) { value in
                    AxisGridLine()
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(verbatim: ChartTimeAxis.label(for: date, in: dateRange))
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                ChartSelectionOverlay(
                    proxy: proxy,
                    selectedDate: selectedBin.map { $0.timestampRange.lowerBound.addingTimeInterval($0.timestampRange.lowerBound.distance(to: $0.timestampRange.upperBound) / 2) },
                    handlesGestures: !isScrollable,
                    selection: selectedDateBinding,
                    dateRange: dateRange,
                    onTap: onTap
                ) {
                    if let selectedBin {
                        selectionBubble(timestampRange: selectedBin.timestampRange, valueRange: selectedBin.valueRange)
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: selectedBinIndex)
            .onChange(of: visibleLength) { oldValue, newValue in
                let center = scrollPosition.addingTimeInterval(oldValue / 2)
                scrollPosition = clampedScrollPosition(center.addingTimeInterval(-newValue / 2), visibleLength: newValue)
            }
            .onChange(of: scrollPosition) { _, newValue in
                let step = ChartWindow.step(for: newValue, in: dateRange, visibleLength: visibleLength)
                if step != windowStep {
                    windowStep = step
                }
            }
    }
    
    @ViewBuilder private var scrollableChart: some View {
        if isScrollable {
            chart
                .chartScrollableAxes(.horizontal)
                .chartXVisibleDomain(length: visibleLength)
                .chartScrollPosition(x: $scrollPosition)
                .chartXSelection(value: selectedDateBinding)
        } else {
            chart
        }
    }
    
    private var chart: some View {
        let valueRange = prepared.valueRange
        return Chart {
            ForEach(renderedItems) { item in
                itemContent(item, minValue: valueRange.lowerBound, maxValue: valueRange.upperBound)
            }
            selectionContent
        }
    }
    
    @ChartContentBuilder
    private func itemContent(_ item: Item, minValue: UInt8, maxValue: UInt8) -> some ChartContent {
        let foregroundStyle = item.active ? AnyShapeStyle(.tint) : AnyShapeStyle(.gray.opacity(0.5))
        let zIndex: Double = item.active ? 1 : 0
        switch item.type {
        case .range(let range):
            BarMark(
                x: .value("timestamp", range.midTimestamp),
                yStart: .value("minimum_beats_per_minute_short", minValue),
                yEnd: .value("maximum_beats_per_minute_short", maxValue),
                width: .inset(2)
            )
            .clipShape(ClipShape(start: range.valueRange.lowerBound, end: range.valueRange.upperBound, min: minValue, max: maxValue))
            .accessibilityValue(Text(verbatim: "\(range.valueRange.lowerBound)–\(range.valueRange.upperBound) " + .init(localized: "beats_per_minute_unit")))
            .foregroundStyle(foregroundStyle)
            .zIndex(zIndex)
        case .sample(let sample):
            BarMark(
                x: .value("timestamp", sample.timestamp),
                yStart: .value("beats_per_minute_unit", minValue),
                yEnd: .value("beats_per_minute_unit", maxValue),
                width: .inset(2)
            )
            .clipShape(ClipShape(start: sample.value, end: sample.value, min: minValue, max: maxValue))
            .accessibilityValue(Text(verbatim: "\(sample.value) " + .init(localized: "beats_per_minute_unit")))
            .foregroundStyle(foregroundStyle)
            .zIndex(zIndex)
        }
    }
    
    @ChartContentBuilder private var selectionContent: some ChartContent {
        if let selectedBin {
            let timestampRange = selectedBin.timestampRange
            RuleMark(x: .value("timestamp", timestampRange.lowerBound.addingTimeInterval(timestampRange.lowerBound.distance(to: timestampRange.upperBound) / 2)))
                .foregroundStyle(.gray.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
                .zIndex(-1)
        }
    }
    
    @ViewBuilder
    private func selectionBubble(timestampRange: Range<Date>, valueRange: ClosedRange<UInt8>) -> some View {
        let unit = String(localized: "beats_per_minute_unit")
        let value = valueRange.lowerBound == valueRange.upperBound
            ? "\(valueRange.lowerBound) \(unit)"
            : "\(valueRange.lowerBound)–\(valueRange.upperBound) \(unit)"
        let start = ChartTimeAxis.preciseLabel(for: timestampRange.lowerBound, in: dateRange)
        let end = ChartTimeAxis.preciseLabel(for: timestampRange.upperBound, in: dateRange)
        ChartSelectionBubble(time: "\(start)–\(end)", value: value)
    }
    
    private func clampedScrollPosition(_ position: Date, visibleLength: TimeInterval) -> Date {
        let maximum = dateRange.upperBound.addingTimeInterval(-visibleLength)
        guard maximum > dateRange.lowerBound else { return dateRange.lowerBound }
        return min(max(position, dateRange.lowerBound), maximum)
    }
    
    /// - Parameters:
    ///   - zoomLevel: Any level narrower than the whole date range makes the chart scroll horizontally. Samples are binned relative to the
    ///     visible length so the bar density stays the same across zoom levels.
    ///   - selection: Defaults to selection state internal to the chart.
    ///   - onTap: Called when the chart is tapped without scrubbing. Only available while the chart shows the whole date range.
    init(
        sectionedSamples: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>,
        dateRange: ClosedRange<Date>,
        zoomLevel: ChartZoomLevel = .whole,
        selection: Binding<Date?>? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.selection = selection
        self.onTap = onTap
        self.zoomLevel = zoomLevel
        self._scrollPosition = State(initialValue: dateRange.lowerBound)
        self.sectionedSamples = sectionedSamples
        self.dateRange = dateRange
    }
    
    init(
        samples: [any WorkoutHeartRateDataSampleProtocol],
        dateRange: ClosedRange<Date>,
        zoomLevel: ChartZoomLevel = .whole,
        selection: Binding<Date?>? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.init(sectionedSamples: [(true, samples)], dateRange: dateRange, zoomLevel: zoomLevel, selection: selection, onTap: onTap)
    }
    
    /// - note: The groups are iterated in bin order so that both the identifiers and the resulting mark order stay
    ///   stable across reconstructions of the chart, which lets Charts diff the marks instead of rebuilding them.
    nonisolated private static func itemize(groups: [Int: [any WorkoutHeartRateDataSampleProtocol]], bins: DateBins) -> [(index: Int, type: ItemType)] {
        var items: [(index: Int, type: ItemType)] = []
        for (index, groupSamples) in groups.sorted(using: KeyPathComparator(\.key)) {
            var minGroupValue = UInt8.max, maxGroupValue = UInt8.min
            for groupSample in groupSamples {
                minGroupValue = min(minGroupValue, groupSample.heartRate)
                maxGroupValue = max(maxGroupValue, groupSample.heartRate)
            }
            let item: ItemType
            let bin = bins[index]
            let timestampRange = bin.lowerBound...bin.upperBound
            if minGroupValue == maxGroupValue, let sample = groupSamples.first {
                let timestamp = timestampRange.lowerBound.addingTimeInterval(timestampRange.lowerBound.distance(to: timestampRange.upperBound) / 2)
                item = .sample(.init(timestamp: timestamp, value: sample.heartRate))
            } else {
                let valueRange = minGroupValue...maxGroupValue
                item = .range(.init(timestampRange: timestampRange, valueRange: valueRange))
            }
            items.append((index, item))
        }
        return items
    }
    
    private struct Prepared {
        
        let activeItems: [Item]
        let inactiveItems: [Item]
        let valueRange: ClosedRange<UInt8>
        let bins: DateBins
        let binValueRanges: [Int: ClosedRange<UInt8>]
        
        init(sectionedSamples: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>, dateRange: ClosedRange<Date>, visibleLength: TimeInterval) {
            let duration = max(dateRange.lowerBound.distance(to: dateRange.upperBound), 1)
            let sampleCount = sectionedSamples.reduce(0) { $0 + $1.elements.count }
            let desiredBinCount = Int(60 * duration / visibleLength)
            let bins = DateBins(range: dateRange, desiredCount: max(min(desiredBinCount, sampleCount), 60))
            self.bins = bins
            guard sampleCount > 0 else {
                self.valueRange = UInt8.min...UInt8.max
                self.activeItems = []
                self.inactiveItems = []
                self.binValueRanges = [:]
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
                    }
                    // always add to inactive group to ensure a continuous segment with active values overlayed
                    inactiveGroups[binIndex, default: []].append(sample)
                }
            }
            self.activeItems = HeartRateChart.itemize(groups: activeGroups, bins: bins).map {
                Item(id: "active-\($0.index)", binIndex: $0.index, active: true, type: $0.type)
            }
            self.inactiveItems = HeartRateChart.itemize(groups: inactiveGroups, bins: bins).map {
                Item(id: "inactive-\($0.index)", binIndex: $0.index, active: false, type: $0.type)
            }
            minValue -= 10 + minValue % 10
            maxValue += 19 - maxValue % 10
            self.valueRange = minValue...maxValue
            self.binValueRanges = inactiveGroups.mapValues { samples in
                let values = samples.map(\.heartRate)
                return values.min()!...values.max()!
            }
        }
    }
    
    private struct PreparedKey: Equatable {
        let dateRange: ClosedRange<Date>
        let sections: ChartSectionsKey
        let visibleLength: TimeInterval
    }
    
    private struct RenderedItemsKey: Equatable {
        let prepared: PreparedKey
        let window: ClosedRange<Date>
    }
    
    private struct Item: Identifiable {
        let id: String
        let binIndex: Int
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
    
    private struct ClipShape: Shape {
        
        let start: UInt8
        let end: UInt8
        let min: UInt8
        let max: UInt8
        
        func path(in rect: CGRect) -> Path {
            let min = CGFloat(min), max = CGFloat(max), start = CGFloat(start), end = CGFloat(end)
            let relativeOriginY = (max - start) / (max - min)
            let relativeHeight = (end - start) / (max - min)
            let originX = rect.origin.x
            var originY = rect.origin.y + relativeOriginY * rect.size.height
            let width = rect.size.width
            var height = relativeHeight * rect.size.height
            let cornerRadius = width / 2
            originY -= cornerRadius
            height += width
            let origin = CGPoint(x: originX, y: originY)
            let size = CGSize(width: width, height: height)
            let newRect = CGRect(origin: origin, size: size)
            return .init(roundedRect: newRect, cornerRadius: cornerRadius)
        }
    }
}
