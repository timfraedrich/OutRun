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
