import Charts
import OutRunCore
import SwiftUI

struct SampleChart<Value: BinaryFloatingPoint & Plottable>: View {
    
    typealias Sample = (timestamp: Date, value: Value)
    
    private let series: [Series]
    private let allItems: [Item]
    private let pauseIndicators: [PauseIndicator]
    private let dateRange: ClosedRange<Date>
    private let yDomain: ClosedRange<Value>?
    private let pauseIndicatorYRange: ClosedRange<Value>?
    private let valueLabelKey: LocalizedStringKey
    
    @Binding private var selectedDate: Date?
    @State private var visibleStartDate: Date
    @State private var visibleDomainLength: TimeInterval
    @State private var pendingMagnification: CGFloat = 1
    @State private var lastPanTranslation: CGFloat = 0
    @State private var isSelecting: Bool = false
    
    private var totalDuration: TimeInterval { dateRange.lowerBound.distance(to: dateRange.upperBound) }
    private var minVisibleDomain: TimeInterval { max(totalDuration / 30, 5) }
    private var visibleDomain: ClosedRange<Date> {
        let end = visibleStartDate.addingTimeInterval(visibleDomainLength)
        return visibleStartDate...end
    }
    private var selectedItem: Item? {
        guard let selectedDate else { return nil }
        let index = allItems.binarySearch { $0.timestamp < selectedDate }
        return allItems[safeIndex: index]
    }
    
    var body: some View {
        chart
            .chartLegend(.hidden)
            .chartForegroundStyleScale(mapping: seriesColor)
            .chartXScale(domain: visibleDomain)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    let plotFrame = proxy.plotFrame.map { geo[$0] } ?? .zero
                    Color.clear
                        .contentShape(.rect)
                        .gesture(zoomGesture)
                        .simultaneousGesture(scrubGesture(proxy: proxy, plotFrame: plotFrame))
                        .simultaneousGesture(panGesture(plotWidth: plotFrame.width))
                        .simultaneousGesture(tapGesture(proxy: proxy, plotFrame: plotFrame))
                }
            }
    }
    
    @ViewBuilder private var chart: some View {
        if let yDomain {
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
        ForEach(series) { series in
            ForEach(series.items) { item in
                LineMark(x: .value("timestamp", item.timestamp), y: .value(valueLabelKey, item.value))
                    .foregroundStyle(by: .value("series", series.id.uuidString))
                    .zIndex(series.active ? 1 : 0)
            }
        }
    }
    
    @ChartContentBuilder private var pauseIndicatorContent: some ChartContent {
        if let pauseIndicatorYRange {
            ForEach(pauseIndicators) { indicator in
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
            .annotation(
                position: .automatic,
                spacing: Spacing.regular.rawValue,
                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .plot))
            ) {
                selectionLabel(for: selectedItem)
            }
            .symbolSize(60)
            .foregroundStyle(.tint)
        }
    }
    
    private func seriesColor(_ plottable: String) -> AnyShapeStyle {
        if let id = UUID(uuidString: plottable), series.first(where: { $0.id == id })?.active == true {
            AnyShapeStyle(.tint)
        } else {
            AnyShapeStyle(.gray.opacity(0.5))
        }
    }
    
    private var zoomGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let magnification = max(value.magnification, 0.01)
                let delta = magnification / pendingMagnification
                pendingMagnification = magnification
                let newLength = visibleDomainLength / delta
                let clampedLength = min(totalDuration, max(minVisibleDomain, newLength))
                let center = visibleStartDate.addingTimeInterval(visibleDomainLength / 2)
                let newStart = center.addingTimeInterval(-clampedLength / 2)
                visibleDomainLength = clampedLength
                visibleStartDate = clampedStart(newStart, length: clampedLength)
            }
            .onEnded { _ in
                pendingMagnification = 1
            }
    }
    
    private func panGesture(plotWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isSelecting, plotWidth > 0 else { return }
                let translation = value.translation.width
                let delta = translation - lastPanTranslation
                lastPanTranslation = translation
                let timeDelta = -Double(delta) / Double(plotWidth) * visibleDomainLength
                let newStart = visibleStartDate.addingTimeInterval(timeDelta)
                visibleStartDate = clampedStart(newStart, length: visibleDomainLength)
            }
            .onEnded { _ in
                lastPanTranslation = 0
            }
    }
    
    private func scrubGesture(proxy: ChartProxy, plotFrame: CGRect) -> some Gesture {
        LongPressGesture(minimumDuration: 0.15)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                isSelecting = true
                guard let drag else { return }
                updateSelection(at: drag.location, proxy: proxy, plotFrame: plotFrame)
            }
            .onEnded { _ in
                isSelecting = false
            }
    }
    
    private func tapGesture(proxy: ChartProxy, plotFrame: CGRect) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                updateSelection(at: value.location, proxy: proxy, plotFrame: plotFrame)
            }
    }
    
    private func updateSelection(at location: CGPoint, proxy: ChartProxy, plotFrame: CGRect) {
        let xInPlot = location.x - plotFrame.origin.x
        guard let date: Date = proxy.value(atX: xInPlot) else { return }
        selectedDate = date
    }
    
    private func clampedStart(_ start: Date, length: TimeInterval) -> Date {
        let minStart = dateRange.lowerBound
        let maxStart = dateRange.upperBound.addingTimeInterval(-length)
        if maxStart < minStart { return minStart }
        if start < minStart { return minStart }
        if start > maxStart { return maxStart }
        return start
    }
    
    @ViewBuilder
    private func selectionLabel(for item: Item) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(item.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(Double(item.value), format: .number.precision(.fractionLength(0...1)))
                .font(.caption.bold())
        }
        .padding(.horizontal, .small)
        .padding(.vertical, .extraSmall)
        .background(in: .capsule)
    }
    
    init(
        _ valueLabelKey: LocalizedStringKey,
        sectionedSamples: CategorizedArray<Bool, Sample>,
        dateRange: ClosedRange<Date>,
        pauses: [any WorkoutPauseProtocol] = [],
        selection: Binding<Date?> = .variable(nil)
    ) {
        self._selectedDate = selection
        let activeSeries: [Series] = sectionedSamples.compactMap { active, samples in
            guard active else { return nil }
            return .init(active: active, items: samples.compactMap { sample in
                let value = sample.value
                guard value >= Value.zero else { return nil }
                return .init(timestamp: sample.timestamp, value: value)
            })
        }
        // we add all samples to an inactive series to have a continuous line in the background
        let allSamples = sectionedSamples.flatMap { $0.elements }.sorted(using: KeyPathComparator(\.timestamp))
        let validItems: [Item] = allSamples.compactMap { sample in
            let value = sample.value
            guard value >= Value.zero else { return nil }
            return .init(timestamp: sample.timestamp, value: value)
        }
        let inactiveSeries: Series = .init(active: false, items: validItems)
        self.series = [inactiveSeries] + activeSeries
        self.allItems = validItems
        self.dateRange = dateRange
        self.valueLabelKey = valueLabelKey
        
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
        let duration = max(dateRange.lowerBound.distance(to: dateRange.upperBound), 1)
        self._visibleDomainLength = State(initialValue: duration)
        self._visibleStartDate = State(initialValue: dateRange.lowerBound)
    }
    
    init(
        _ valueLabelKey: LocalizedStringKey,
        samples: [Sample],
        dateRange: ClosedRange<Date>,
        pauses: [any WorkoutPauseProtocol] = [],
        selection: Binding<Date?> = .variable(nil)
    ) {
        self.init(valueLabelKey, sectionedSamples: [(true, samples)], dateRange: dateRange, pauses: pauses, selection: selection)
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
    
    private struct PauseIndicator: Identifiable {
        let id = UUID()
        let number: Int
        let startDate: Date
        let endDate: Date
    }
}
