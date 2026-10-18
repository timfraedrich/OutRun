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
@testable import OutRunCore
import Testing

@Suite("Pause Merging Tests")
struct PauseMergingTests {

    private let start = Date(timeIntervalSinceReferenceDate: 0)

    private func date(_ offset: TimeInterval) -> Date {
        start.addingTimeInterval(offset)
    }

    @Test("No Pauses")
    func noPauses() {
        #expect(Calculation.calculateMergedPauseIntervals(from: []).isEmpty)
    }

    @Test("Separate Pauses Stay Separate")
    func separatePauses() {
        let pauses = [
            RawWorkoutPause(startDate: date(10), endDate: date(20), userInitiated: true),
            RawWorkoutPause(startDate: date(30), endDate: date(40), userInitiated: false),
        ]
        let intervals = Calculation.calculateMergedPauseIntervals(from: pauses)
        #expect(intervals == [.init(start: date(10), end: date(20)), .init(start: date(30), end: date(40))])
    }

    @Test("Automatic Pause Followed By Manual Pause Is Merged")
    func adjacentPausesAreMerged() {
        let pauses = [
            RawWorkoutPause(startDate: date(10), endDate: date(20), userInitiated: false),
            RawWorkoutPause(startDate: date(20), endDate: date(40), userInitiated: true),
        ]
        let intervals = Calculation.calculateMergedPauseIntervals(from: pauses)
        #expect(intervals == [.init(start: date(10), end: date(40))])
    }

    @Test("Unsorted Overlapping Pauses Are Merged")
    func unsortedOverlappingPausesAreMerged() {
        let pauses = [
            RawWorkoutPause(startDate: date(50), endDate: date(60), userInitiated: true),
            RawWorkoutPause(startDate: date(15), endDate: date(18), userInitiated: false),
            RawWorkoutPause(startDate: date(10), endDate: date(20), userInitiated: true),
            RawWorkoutPause(startDate: date(20), endDate: date(30), userInitiated: false),
        ]
        let intervals = Calculation.calculateMergedPauseIntervals(from: pauses)
        #expect(intervals == [.init(start: date(10), end: date(30)), .init(start: date(50), end: date(60))])
    }
}
