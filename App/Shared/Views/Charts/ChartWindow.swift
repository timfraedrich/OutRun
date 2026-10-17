import Foundation

/// The part of a horizontally scrolling chart that is rendered, covering the visible domain with a margin on both sides.
/// - note: The window only moves in steps of the visible length, so the chart content is rebuilt once per step instead of on every scroll
///   frame.
struct ChartWindow: Equatable {
    
    let range: ClosedRange<Date>
    
    init(dateRange: ClosedRange<Date>, visibleLength: TimeInterval, step: Int) {
        let start = dateRange.lowerBound.addingTimeInterval(Double(step - 1) * visibleLength)
        let end = dateRange.lowerBound.addingTimeInterval(Double(step + 3) * visibleLength)
        let lowerBound = min(max(start, dateRange.lowerBound), dateRange.upperBound)
        self.range = lowerBound...max(min(end, dateRange.upperBound), lowerBound)
    }
    
    static func step(for scrollPosition: Date, in dateRange: ClosedRange<Date>, visibleLength: TimeInterval) -> Int {
        guard visibleLength > 0 else { return 0 }
        return max(Int(dateRange.lowerBound.distance(to: scrollPosition) / visibleLength), 0)
    }
}
