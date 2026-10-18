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

import Charts
import OutRunCore
import SwiftUI

struct SampleChart<Value: BinaryFloatingPoint & Plottable>: View {
    
    typealias Sample = (timestamp: Date, value: Value)
    
    @State private var internalSelectedDate: Date?
    @State private var scrollPosition: Date
    @State private var windowStep = 0
    @State private var preparedMemo = ChartMemo<PreparedKey, Prepared>()
    @State private var renderedSeriesMemo = ChartMemo<RenderedSeriesKey, [Series]>()
    
    private let sectionedSamples: CategorizedArray<Bool, Sample>
    private let pauses: [any WorkoutPauseProtocol]
    private let dateRange: ClosedRange<Date>
    private let valueLabelKey: LocalizedStringKey
    private let valueFormatter: MeasurementFormatter
    private let unit: Unit
    private let zoomLevel: ChartZoomLevel
    private let selection: Binding<Date?>?
    private let onTap: (() -> Void)?
    
    private var duration: TimeInterval { max(dateRange.lowerBound.distance(to: dateRange.upperBound), 1) }
    private var visibleLength: TimeInterval { zoomLevel.visibleLength(for: duration) }
    private var isScrollable: Bool { visibleLength < duration }
    private var preparedKey: PreparedKey {
        PreparedKey(
            dateRange: dateRange,
            sections: ChartSectionsKey(sectionedSamples, timestamp: \.timestamp),
            pauses: pauses.map { $0.startDate...$0.endDate },
            unit: unit
        )
    }
    /// - note: Derived from the samples once per change of the input data instead of on every view update, e.g. while scrubbing
    ///   updates the selection of a parent.
    private var prepared: Prepared {
        preparedMemo.value(for: preparedKey) {
            Prepared(sectionedSamples: sectionedSamples, dateRange: dateRange, pauses: pauses)
        }
    }
    private var renderedWindow: ClosedRange<Date> {
        guard isScrollable else { return dateRange }
        return ChartWindow(dateRange: dateRange, visibleLength: visibleLength, step: windowStep).range
    }
    /// The series limited to the rendered window and reduced to the resolution of the plot, as Charts gets slow with thousands of marks.
    private var renderedSeries: [Series] {
        let window = renderedWindow
        let bucketLength = visibleLength / 150
        let key = RenderedSeriesKey(prepared: preparedKey, window: window, bucketLength: bucketLength)
        return renderedSeriesMemo.value(for: key) {
            prepared.series.compactMap { series in
                let items = Self.reduced(series.items, in: window, bucketLength: bucketLength, origin: dateRange.lowerBound)
                return items.isEmpty ? nil : Series(id: series.id, active: series.active, items: items)
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
    private var selectedItem: Item? {
        let allItems = prepared.allItems
        guard let selectedDate, !allItems.isEmpty else { return nil }
        let index = allItems.binarySearch { $0.timestamp < selectedDate }
        let candidates = [allItems[safeIndex: index - 1], allItems[safeIndex: index]].compactMap { $0 }
        return candidates.min { abs($0.timestamp.distance(to: selectedDate)) < abs($1.timestamp.distance(to: selectedDate)) }
    }
    
    var body: some View {
        scrollableChart
            .chartLegend(.hidden)
            .chartForegroundStyleScale(mapping: seriesColor)
            .chartXScale(domain: dateRange)
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
                    selectedDate: selectedItem?.timestamp,
                    handlesGestures: !isScrollable,
                    selection: selectedDateBinding,
                    dateRange: dateRange,
                    onTap: onTap
                ) {
                    if let selectedItem {
                        ChartSelectionBubble(
                            time: ChartTimeAxis.preciseLabel(for: selectedItem.timestamp, in: dateRange),
                            value: valueFormatter.string(from: Measurement(value: Double(selectedItem.value), unit: unit))
                        )
                    }
                }
            }
            .throttledSelectionFeedback(trigger: selectedItem?.id)
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
    
    @ViewBuilder private var chart: some View {
        if let yDomain = prepared.yDomain {
            Chart(content: chartContent)
                .chartYScale(domain: yDomain)
        } else {
            Chart(content: chartContent)
        }
    }
    
    @ChartContentBuilder private func chartContent() -> some ChartContent {
        seriesContent
        pauseIndicatorContent
        selectionContent
    }
    
    @ChartContentBuilder private var seriesContent: some ChartContent {
        ForEach(renderedSeries) { series in
            ForEach(series.items) { item in
                LineMark(x: .value("timestamp", item.timestamp), y: .value(valueLabelKey, item.value))
                    .foregroundStyle(by: .value("series", series.id))
                    .zIndex(series.active ? 1 : 0)
            }
        }
    }
    
    @ChartContentBuilder private var pauseIndicatorContent: some ChartContent {
        if let pauseIndicatorYRange = prepared.pauseIndicatorYRange {
            ForEach(prepared.pauseIndicators) { indicator in
                RectangleMark(
                    xStart: .value("pause_start", indicator.startDate),
                    xEnd: .value("pause_end", indicator.endDate),
                    yStart: .value(valueLabelKey, pauseIndicatorYRange.lowerBound),
                    yEnd: .value(valueLabelKey, pauseIndicatorYRange.upperBound)
                )
                .clipShape(.capsule)
                .foregroundStyle(.gray)
                .annotation(position: .overlay) {
                    Text(verbatim: "\(indicator.number)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    @ChartContentBuilder private var selectionContent: some ChartContent {
        if let selectedItem {
            RuleMark(x: .value("selected_value", selectedItem.timestamp))
                .foregroundStyle(.gray.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 2]))
            PointMark(
                x: .value("selected_timestamp", selectedItem.timestamp),
                y: .value(valueLabelKey, selectedItem.value)
            )
            .symbolSize(60)
            .foregroundStyle(.tint)
        }
    }
    
    private func seriesColor(_ plottable: Int) -> AnyShapeStyle {
        if plottable != Prepared.inactiveSeriesID {
            AnyShapeStyle(.tint)
        } else {
            AnyShapeStyle(.gray.opacity(0.5))
        }
    }
    
    /// Keeps the lowest and highest value per bucket in chronological order, which preserves peaks while limiting the number of marks.
    /// Buckets are anchored to the origin so the reduced line does not change shape while the window moves.
    private static func reduced(_ items: [Item], in window: ClosedRange<Date>, bucketLength: TimeInterval, origin: Date) -> [Item] {
        // include one item beyond each edge so the line continues out of the window
        let lowerIndex = max(items.binarySearch { $0.timestamp < window.lowerBound } - 1, items.startIndex)
        let upperIndex = min(items.binarySearch { $0.timestamp <= window.upperBound } + 1, items.endIndex)
        guard lowerIndex < upperIndex else { return [] }
        guard bucketLength > 0 else { return Array(items[lowerIndex..<upperIndex]) }
        var result: [Item] = []
        var bucket: Int?
        var minimum: Item?
        var maximum: Item?
        func flush() {
            guard let minimum, let maximum else { return }
            if minimum.id == maximum.id {
                result.append(minimum)
            } else if minimum.timestamp < maximum.timestamp {
                result.append(contentsOf: [minimum, maximum])
            } else {
                result.append(contentsOf: [maximum, minimum])
            }
        }
        for item in items[lowerIndex..<upperIndex] {
            let itemBucket = Int((origin.distance(to: item.timestamp) / bucketLength).rounded(.down))
            if itemBucket != bucket {
                flush()
                bucket = itemBucket
                minimum = item
                maximum = item
            } else {
                if let current = minimum, item.value < current.value { minimum = item }
                if let current = maximum, item.value > current.value { maximum = item }
            }
        }
        flush()
        return result
    }
    
    private func clampedScrollPosition(_ position: Date, visibleLength: TimeInterval) -> Date {
        let maximum = dateRange.upperBound.addingTimeInterval(-visibleLength)
        guard maximum > dateRange.lowerBound else { return dateRange.lowerBound }
        return min(max(position, dateRange.lowerBound), maximum)
    }
    
    /// - Parameters:
    ///   - unit: The unit the sample values are expressed in, used to format the selected value.
    ///   - zoomLevel: Any level narrower than the whole date range makes the chart scroll horizontally.
    ///   - selection: Defaults to selection state internal to the chart.
    ///   - onTap: Called when the chart is tapped without scrubbing. Only available while the chart shows the whole date range.
    init(
        _ valueLabelKey: LocalizedStringKey,
        unit: Unit,
        sectionedSamples: CategorizedArray<Bool, Sample>,
        dateRange: ClosedRange<Date>,
        pauses: [any WorkoutPauseProtocol] = [],
        zoomLevel: ChartZoomLevel = .whole,
        selection: Binding<Date?>? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.selection = selection
        self.onTap = onTap
        self.zoomLevel = zoomLevel
        self.unit = unit
        let valueFormatter = MeasurementFormatter()
        valueFormatter.unitOptions = .providedUnit
        valueFormatter.unitStyle = .medium
        valueFormatter.numberFormatter.maximumFractionDigits = 1
        self.valueFormatter = valueFormatter
        self.sectionedSamples = sectionedSamples
        self.pauses = pauses
        self.dateRange = dateRange
        self.valueLabelKey = valueLabelKey
        self._scrollPosition = State(initialValue: dateRange.lowerBound)
    }
    
    init(
        _ valueLabelKey: LocalizedStringKey,
        unit: Unit,
        samples: [Sample],
        dateRange: ClosedRange<Date>,
        pauses: [any WorkoutPauseProtocol] = [],
        zoomLevel: ChartZoomLevel = .whole,
        selection: Binding<Date?>? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.init(
            valueLabelKey,
            unit: unit,
            sectionedSamples: [(true, samples)],
            dateRange: dateRange,
            pauses: pauses,
            zoomLevel: zoomLevel,
            selection: selection,
            onTap: onTap
        )
    }
    
    private struct Prepared {
        
        static var inactiveSeriesID: Int { 0 }
        
        let series: [Series]
        let allItems: [Item]
        let pauseIndicators: [PauseIndicator]
        let yDomain: ClosedRange<Value>?
        let pauseIndicatorYRange: ClosedRange<Value>?
        
        init(sectionedSamples: CategorizedArray<Bool, Sample>, dateRange: ClosedRange<Date>, pauses: [any WorkoutPauseProtocol]) {
            // we add all samples to an inactive series to have a continuous line in the background
            let allSamples = sectionedSamples.flatMap { $0.elements }.sorted(using: KeyPathComparator(\.timestamp))
            let validItems: [Item] = allSamples.enumerated().compactMap { index, sample in
                let value = sample.value
                guard value >= Value.zero else { return nil }
                return .init(id: index, timestamp: sample.timestamp, value: value)
            }
            let inactiveSeries: Series = .init(id: Self.inactiveSeriesID, active: false, items: validItems)
            var activeSeries: [Series] = []
            for (active, samples) in sectionedSamples where active {
                let items: [Item] = samples.enumerated().compactMap { index, sample in
                    let value = sample.value
                    guard value >= Value.zero else { return nil }
                    return .init(id: index, timestamp: sample.timestamp, value: value)
                }
                activeSeries.append(.init(id: activeSeries.count + 1, active: true, items: items))
            }
            self.series = [inactiveSeries] + activeSeries
            self.allItems = validItems
            
            let numberedPauses = pauses
                .sorted(using: KeyPathComparator(\.startDate))
                .enumerated()
                .map { index, pause in
                    PauseIndicator(
                        number: index + 1,
                        startDate: max(pause.startDate, dateRange.lowerBound),
                        endDate: min(pause.endDate, dateRange.upperBound)
                    )
                }
                .filter { $0.startDate < $0.endDate }
            self.pauseIndicators = numberedPauses
            
            let values = validItems.map(\.value)
            if var minValue = values.min(), var maxValue = values.max(), maxValue > minValue {
                var dataRange = maxValue - minValue
                minValue -= dataRange * 0.10
                maxValue += dataRange * 0.10
                dataRange = maxValue - minValue
                if numberedPauses.isEmpty {
                    self.yDomain = minValue...maxValue
                    self.pauseIndicatorYRange = nil
                } else {
                    let indicatorPaddingBottom: Value = dataRange * 0.04
                    let indicatorHeight: Value = dataRange * 0.10
                    let indicatorBottom = maxValue + indicatorPaddingBottom
                    let indicatorTop = indicatorBottom + indicatorHeight
                    self.yDomain = minValue...indicatorTop
                    self.pauseIndicatorYRange = indicatorBottom...indicatorTop
                }
            } else {
                self.yDomain = nil
                self.pauseIndicatorYRange = nil
            }
        }
    }
    
    private struct PreparedKey: Equatable {
        let dateRange: ClosedRange<Date>
        let sections: ChartSectionsKey
        let pauses: [ClosedRange<Date>]
        let unit: Unit
    }
    
    private struct RenderedSeriesKey: Equatable {
        let prepared: PreparedKey
        let window: ClosedRange<Date>
        let bucketLength: TimeInterval
    }
    
    private struct Series: Identifiable {
        let id: Int
        let active: Bool
        let items: [Item]
    }
    
    private struct Item: Identifiable {
        let id: Int
        let timestamp: Date
        let value: Value
    }
    
    private struct PauseIndicator: Identifiable {
        var id: Int { number }
        let number: Int
        let startDate: Date
        let endDate: Date
    }
}
