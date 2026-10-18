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

import ActivityKit
import OSLog
import OutRunCore
import Perception

/// Keeps a live activity in sync with the workout recorded by the ``WorkoutRecorder`` of the core.
@MainActor
final class WorkoutLiveActivityService {

    private typealias ContentState = WorkoutAttributes.ContentState

    private static let minimumUpdateInterval: Duration = .seconds(1)
    private nonisolated static let logger = Logger(category: "WorkoutLiveActivityService")

    private let core: OutRunCore
    private var activityID: Activity<WorkoutAttributes>.ID?

    /// Starts monitoring the recorder of the provided core for as long as the app is running, independent of any UI being loaded.
    init(core: OutRunCore) {
        self.core = core
        Task { await monitorRecorders() }
    }

    private func monitorRecorders() async {
        var monitoredRecorder: WorkoutRecorder?
        var monitoringTask: Task<Void, Never>?
        let recorders = Perceptions { [core] () -> WorkoutRecorder? in
            guard case .initialized = core.status else { return nil }
            return core.recorder
        }
        for await recorder in recorders where recorder !== monitoredRecorder {
            monitoringTask?.cancel()
            monitoredRecorder = recorder
            monitoringTask = recorder.map { recorder in Task { await monitor(recorder) } }
        }
    }

    /// Starts, updates and ends the live activity according to the state of the recorder until the calling task is cancelled.
    /// - note: Cancelling the task leaves a running live activity untouched, it is adopted once monitoring is resumed.
    private func monitor(_ recorder: WorkoutRecorder) async {
        let contentStates = Perceptions { [core] in
            Self.contentState(for: recorder, preferences: core.userPreferences?.preferences)
        }
        for await contentState in contentStates {
            if let contentState {
                activityID = await Self.startOrUpdateActivity(withID: activityID, contentState: contentState)
            } else {
                activityID = nil
                await Self.endActivities()
            }
            try? await Task.sleep(for: Self.minimumUpdateInterval)
        }
    }

    private static func contentState(for recorder: WorkoutRecorder, preferences: RawPreferences?) -> ContentState? {
        guard recorder.status.isCollectingData else { return nil }
        return .init(
            type: recorder.workoutType,
            isPaused: recorder.status.isPaused,
            duration: recorder.duration,
            distance: recorder.distance,
            preferences: preferences ?? [:]
        )
    }

    /// - returns: The identifier of the live activity representing the workout, `nil` if none is running.
    @concurrent
    private nonisolated static func startOrUpdateActivity(
        withID activityID: Activity<WorkoutAttributes>.ID?,
        contentState: ContentState
    ) async -> Activity<WorkoutAttributes>.ID? {
        let content = ActivityContent(state: contentState, staleDate: nil)
        let activities = Activity<WorkoutAttributes>.activities
        if let activityID = activityID ?? activities.first(where: isOngoing)?.id {
            // a live activity dismissed by the user is not brought back until the next workout
            guard let activity = activities.first(where: { $0.id == activityID }),
                  isOngoing(activity),
                  activity.content.state != contentState
            else { return activityID }
            await activity.update(content)
            return activityID
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return nil }
        do {
            let activity = try Activity.request(attributes: WorkoutAttributes(), content: content)
            logger.info("Started workout live activity.")
            return activity.id
        } catch {
            logger.error("Failed to start workout live activity: \((error as CustomDebugStringConvertible).debugDescription).")
            return nil
        }
    }

    @concurrent
    private nonisolated static func endActivities() async {
        for activity in Activity<WorkoutAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
            logger.info("Ended workout live activity.")
        }
    }

    private nonisolated static func isOngoing(_ activity: Activity<WorkoutAttributes>) -> Bool {
        activity.activityState == .active || activity.activityState == .stale
    }
}
