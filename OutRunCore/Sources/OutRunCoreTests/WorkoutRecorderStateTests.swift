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

    private func makeUser(pauseAutomatically: Bool) -> RawUser {
        let preferences = UserPreferences(preferences: [:])
        preferences.pauseAutomatically = pauseAutomatically
        return RawUser(name: "Test", preferences: preferences.preferences, creationDate: startDate)
    }

    private func makeState(
        pauseAutomatically: Bool = false,
        type: WorkoutType = .running,
        locationBeforeStart: CLLocation? = nil
    ) throws -> WorkoutRecorderState {
        let state = WorkoutRecorderState(user: makeUser(pauseAutomatically: pauseAutomatically), latestWorkoutType: type)
        try state.signalSuccessfulInitialization()
        if let locationBeforeStart {
            _ = try state.processLocation(locationBeforeStart, with: nil)
        }
        let workout = RawWorkout(
            id: .init(),
            type: type,
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

    private func location(
        steps: Int,
        at offset: TimeInterval,
        speed: CLLocationSpeed = -1,
        accuracy: CLLocationAccuracy = 5
    ) -> CLLocation {
        CLLocation(
            coordinate: .init(latitude: Double(steps) * step, longitude: 0),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: 5,
            course: -1,
            speed: speed,
            timestamp: startDate.addingTimeInterval(offset)
        )
    }

    private func date(_ offset: TimeInterval) -> Date {
        startDate.addingTimeInterval(offset)
    }

    /// Feeds one location per second at running speed, starting at the given step and offset.
    @discardableResult
    private func run(
        _ state: WorkoutRecorderState,
        from steps: Int,
        at offset: TimeInterval,
        count: Int
    ) throws -> [RawWorkoutPause] {
        try (0..<count).compactMap { index in
            try state.processLocation(location(steps: steps + index, at: offset + Double(index), speed: 3), with: nil).pause
        }
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

    @Test("Locations with invalid accuracy are rejected")
    func invalidAccuracyIsRejected() throws {
        let state = try makeState()
        #expect(try state.processLocation(location(steps: 0, at: 1, accuracy: -1), with: nil).sample == nil)
        #expect(state.route.isEmpty)
    }

    @Test("Relative altitude is applied on top of the altitude of the first sample")
    func relativeAltitudeIsRefined() throws {
        let state = try makeState()
        let altitude = { (value: Double) in AltitudeService.AltitudeSample(isAbsolute: false, timestamp: .now, altitude: value) }
        let first = try state.processLocation(location(steps: 0, at: 1), with: altitude(2)).sample
        let second = try state.processLocation(location(steps: 1, at: 2), with: altitude(5)).sample
        #expect(first?.altitude == 0)
        #expect(second?.altitude == 3)
    }

    @Test("Ending during a manual pause returns the running pause")
    func endReturnsRunningManualPause() throws {
        let state = try makeState()
        try run(state, from: 0, at: 1, count: 2)
        _ = try state.pause(on: date(3))
        let pause = try state.end(on: date(20))
        #expect(pause?.startDate == date(3))
        #expect(pause?.endDate == date(20))
        #expect(pause?.userInitiated == true)
        #expect(state.status == .idle)
    }

    @Test("Ending during an automatic pause returns the running pause")
    func endReturnsRunningAutomaticPause() throws {
        let state = try makeState(pauseAutomatically: true)
        try run(state, from: 0, at: 1, count: 2)
        _ = try state.processLocation(location(steps: 2, at: 3, speed: 0), with: nil)
        let pause = try state.end(on: date(20))
        #expect(pause?.startDate == date(3))
        #expect(pause?.endDate == date(20))
        #expect(pause?.userInitiated == false)
    }

    @Test("Slow locations are recorded during a manual pause and continue as an automatic pause after it")
    func automaticPauseDuringManualPause() throws {
        let state = try makeState(pauseAutomatically: true)
        try run(state, from: 0, at: 1, count: 2)
        _ = try state.pause(on: date(3))
        let result = try state.processLocation(location(steps: 3, at: 4, speed: 0), with: nil)
        #expect(result.sample != nil)
        #expect(result.pause == nil)
        #expect(state.status == .paused(manual: true))

        let manualPause = try state.resume(on: date(10))
        #expect(manualPause?.startDate == date(3))
        #expect(manualPause?.userInitiated == true)
        #expect(state.status == .paused(manual: false))

        let automaticPause = try state.processLocation(location(steps: 4, at: 20, speed: 3), with: nil).pause
        #expect(state.status == .recording)
        #expect(automaticPause?.startDate == date(10))
        #expect(automaticPause?.endDate == date(20))
        #expect(automaticPause?.userInitiated == false)
    }

    @Test("A discarded short automatic pause counts towards the active duration")
    func shortAutomaticPauseCountsAsActive() throws {
        let state = try makeState(pauseAutomatically: true)
        try run(state, from: 0, at: 0, count: 3)
        _ = try state.processLocation(location(steps: 3, at: 3, speed: 0), with: nil)
        let pause = try state.processLocation(location(steps: 4, at: 5, speed: 3), with: nil).pause
        #expect(pause == nil)
        #expect(state.activeDuration.timeInterval(for: date(10)) == 10)
    }

    @Test("An automatic pause detected from a delayed location does not start before a manual resume")
    func delayedLocationDoesNotStartPauseBeforeResume() throws {
        let state = try makeState(pauseAutomatically: true)
        try run(state, from: 0, at: 1, count: 2)
        _ = try state.pause(on: date(3))
        _ = try state.resume(on: date(10))
        _ = try state.processLocation(location(steps: 2, at: 9.5, speed: 0), with: nil)
        #expect(state.status == .paused(manual: false))
        #expect(state.activeDuration.timeInterval(for: date(20)) == 3)
        let pause = try state.end(on: date(20))
        #expect(pause?.startDate == date(10))
    }

    @Test("Recording continues after a GPS outage")
    func recordingContinuesAfterGPSOutage() throws {
        let state = try makeState(pauseAutomatically: true)
        try run(state, from: 0, at: 1, count: 5)
        let distanceBeforeOutage = state.distance
        for offset in stride(from: 6.0, to: 66, by: 1) {
            #expect(try state.processLocation(location(steps: 4, at: offset, accuracy: 165), with: nil).sample == nil)
        }
        #expect(try state.processLocation(location(steps: 30, at: 66, speed: 3), with: nil).sample != nil)
        #expect(state.status == .recording)
        #expect(state.distance > distanceBeforeOutage + 250)
    }

    @Test("An automatic pause started before a GPS outage ends once a valid speed is reported again")
    func automaticPauseEndsAfterGPSOutage() throws {
        let state = try makeState(pauseAutomatically: true)
        try run(state, from: 0, at: 1, count: 3)
        _ = try state.processLocation(location(steps: 3, at: 4, speed: 0.5), with: nil)
        #expect(state.status == .paused(manual: false))
        #expect(try state.processLocation(location(steps: 10, at: 60), with: nil).sample != nil)
        #expect(state.status == .paused(manual: false))
        let pause = try state.processLocation(location(steps: 11, at: 61, speed: 3), with: nil).pause
        #expect(state.status == .recording)
        #expect(pause?.startDate == date(4))
        #expect(pause?.endDate == date(61))
        let distanceAfterResume = state.distance
        try run(state, from: 12, at: 62, count: 2)
        #expect(state.distance > distanceAfterResume + 20)
    }

    @Test("Slow locations do not pause the workout when automatic pauses are disabled")
    func noAutomaticPauseWhenDisabled() throws {
        let state = try makeState(pauseAutomatically: false, locationBeforeStart: location(steps: 0, at: -1, speed: 0))
        #expect(state.status == .recording)
        _ = try state.processLocation(location(steps: 0, at: 1, speed: 0), with: nil)
        #expect(state.status == .recording)
    }

    @Test("Disabling automatic pauses ends a running automatic pause")
    func disablingAutomaticPausesEndsPause() throws {
        let state = try makeState(pauseAutomatically: true)
        try run(state, from: 0, at: 1, count: 2)
        _ = try state.processLocation(location(steps: 2, at: 3, speed: 0), with: nil)
        #expect(state.status == .paused(manual: false))
        state.update(basedOn: makeUser(pauseAutomatically: false))
        let pause = try state.processLocation(location(steps: 3, at: 10, speed: 0), with: nil).pause
        #expect(state.status == .recording)
        #expect(pause?.startDate == date(3))
        #expect(pause?.endDate == date(10))
    }

    @Test("Switching to a workout type without automatic pauses ends a running automatic pause")
    func switchingToTypeWithoutAutomaticPausesEndsPause() throws {
        let state = try makeState(pauseAutomatically: true)
        try run(state, from: 0, at: 1, count: 2)
        _ = try state.processLocation(location(steps: 2, at: 3, speed: 0), with: nil)
        #expect(state.status == .paused(manual: false))
        state.changeWorkoutType(to: .hiking)
        let pause = try state.processLocation(location(steps: 3, at: 10, speed: 0), with: nil).pause
        #expect(state.status == .recording)
        #expect(pause?.startDate == date(3))
    }
}
