import Foundation

enum ChartZoomLevel: Hashable, Identifiable {
    
    case whole
    case span(TimeInterval)
    
    var id: Self { self }
    
    /// - note: Falls back to the whole duration when the level is not offered for it, e.g. after the duration was shortened.
    func visibleLength(for duration: TimeInterval) -> TimeInterval {
        switch self {
        case .whole: duration
        case .span(let length): Self.isMeaningful(length, for: duration) ? length : duration
        }
    }
    
    /// The zoom levels that meaningfully differ from showing the whole duration.
    static func levels(for duration: TimeInterval) -> [ChartZoomLevel] {
        [.whole] + [1800, 900, 300, 60].filter { isMeaningful($0, for: duration) }.map(ChartZoomLevel.span)
    }
    
    private static func isMeaningful(_ length: TimeInterval, for duration: TimeInterval) -> Bool {
        length * 1.5 < duration
    }
}
