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

import CoreLocation
import Foundation
@testable import OutRunCore
import Testing

@Suite("Workout Recorder State Tests")
@BackgroundActor
struct WorkoutRecorderStateTests {

    private let startDate = Date(timeIntervalSinceReferenceDate: 0)
    /// Roughly 11 meters in latitude.
    private let step: CLLocationDegrees = 0.0001

    private func makeState() throws -> WorkoutRecorderState {
        let preferences = UserPreferences(preferences: [:])
        preferences.pauseAutomatically = false
        let user = RawUser(name: "Test", preferences: preferences.preferences, creationDate: startDate)
        let state = WorkoutRecorderState(user: user, latestWorkoutType: .running)
        try state.signalSuccessfulInitialization()
        let workout = RawWorkout(
            id: .init(),
            type: .running,
            distance: .zero,
            startDate: startDate,
            endDate: nil,
            energy: nil,
            repetitions: nil,
            isRace: false,
            name: nil,
            comment: nil,
            creationDate: startDate,
            lastEditDate: startDate,
            source: .native
        )
        try state.startOrContinue(workout, on: startDate)
        return state
    }

    private func location(steps: Int, at offset: TimeInterval) -> CLLocation {
        CLLocation(
            coordinate: .init(latitude: Double(steps) * step, longitude: 0),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: -1,
            speed: -1,
            timestamp: startDate.addingTimeInterval(offset)
        )
    }

    @Test("Locations are recorded during a pause without changing the live metrics")
    func locationsAreRecordedDuringPause() throws {
        let state = try makeState()
        #expect(try state.processLocation(location(steps: 0, at: 1), with: nil).sample != nil)
        #expect(try state.processLocation(location(steps: 1, at: 3), with: nil).sample != nil)
        let distanceBeforePause = state.distance
        #expect(distanceBeforePause > 10)

        _ = try state.pause(on: startDate.addingTimeInterval(4))
        #expect(try state.processLocation(location(steps: 1, at: 15), with: nil).sample != nil)
        #expect(try state.processLocation(location(steps: 1, at: 27), with: nil).sample != nil)
        #expect(try state.processLocation(location(steps: 2, at: 29), with: nil).sample != nil)
        #expect(state.distance == distanceBeforePause)

        _ = try state.resume(on: startDate.addingTimeInterval(30))
        #expect(try state.processLocation(location(steps: 3, at: 32), with: nil).sample != nil)
        #expect(state.distance == distanceBeforePause)
        #expect(try state.processLocation(location(steps: 4, at: 34), with: nil).sample != nil)
        #expect(state.distance > distanceBeforePause + 10)
        #expect(state.route.count == 7)
    }

    @Test("Locations recorded during a pause are filtered by time and distance")
    func locationsDuringPauseAreFiltered() throws {
        let state = try makeState()
        #expect(try state.processLocation(location(steps: 0, at: 1), with: nil).sample != nil)
        _ = try state.pause(on: startDate.addingTimeInterval(2))
        #expect(try state.processLocation(location(steps: 0, at: 5), with: nil).sample == nil)
        #expect(try state.processLocation(location(steps: 0, at: 12), with: nil).sample != nil)
    }
}
