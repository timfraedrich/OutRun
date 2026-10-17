import Foundation

/// Formats chart time axes as time elapsed since the start of the plotted range.
enum ChartTimeAxis {
    
    private static let strides: [TimeInterval] = [10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600, 7200, 10800]

    /// Axis values are anchored to the start of the range in fixed strides, so labels keep their position relative to the data instead of
    /// being redistributed whenever the visible domain changes.
    /// - Parameter window: Limits the values to the rendered part of the range, defaults to the whole range.
    static func values(
        in range: ClosedRange<Date>,
        visibleLength: TimeInterval,
        window: ClosedRange<Date>? = nil,
        desiredCount: Int = 4
    ) -> [Date] {
        let stride = strides.first { visibleLength / $0 <= Double(desiredCount) } ?? strides[strides.count - 1]
        let window = window ?? range
        let firstStep = max((range.lowerBound.distance(to: window.lowerBound) / stride).rounded(.up), 0)
        let first = range.lowerBound.addingTimeInterval(firstStep * stride)
        return Array(Swift.stride(from: first, through: min(window.upperBound, range.upperBound), by: stride))
    }
    
    static func label(for date: Date, in range: ClosedRange<Date>) -> String {
        let total = range.lowerBound.distance(to: range.upperBound)
        return elapsed(until: date, in: range).formatted(.time(pattern: total >= 3600 ? .hourMinute : .minuteSecond))
    }
    
    static func preciseLabel(for date: Date, in range: ClosedRange<Date>) -> String {
        let total = range.lowerBound.distance(to: range.upperBound)
        return elapsed(until: date, in: range).formatted(.time(pattern: total >= 3600 ? .hourMinuteSecond : .minuteSecond))
    }
    
    private static func elapsed(until date: Date, in range: ClosedRange<Date>) -> Duration {
        .seconds(max(0, range.lowerBound.distance(to: date)).rounded())
    }
}
