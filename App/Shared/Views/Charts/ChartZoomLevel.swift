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
