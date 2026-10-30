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
import MapKit
import OutRunCore
import StoreKit
import SwiftData
import SwiftUI
import TFRouting

struct RecordingScene: View {
    
    @Environment(\.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @Environment(OutRunCore.self) private var core
    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(Router.self) private var router

    @State private var keepUserCentered: Bool = true
    @State private var error: Error?
    @State private var permissionNoticeIsPresented: Bool = false
    @State private var finishedWorkoutID: Workout.ID?

    private static let reviewRequestWorkoutThreshold = 3
    
    private let padding: Spacing = if #available(iOS 26.0, *) { .large } else { .regular }
    
    private var errorIsPresented: Binding<Bool> {
        Binding {
            error != nil
        } set: { isPresented in
            guard !isPresented else { return }
            error = nil
        }
    }
    
    private var duration: WorkoutMetric.ValueRepresentation {
        switch recorder.duration {
        case .constant(let timeInterval): .duration(timeInterval)
        case .increasing(let startDate, let offset): .increasingDuration(startDate, offset)
        }
    }
    
    private var requiredPermissionsMissing: Bool {
        recorder.missingPermissions.contains { $0.isRequired }
    }

    private var workoutTypeBinding: Binding<WorkoutType> {
        .init(
            get: { recorder.workoutType },
            set: { type in
                Task {
                    do {
                        try await recorder.changeWorkoutType(to: type)
                    } catch {
                        self.error = error
                    }
                }
            }
        )
    }
    
    // MARK: Views
    
    var body: some View {
        @Bindable var recorder = recorder
        WorkoutMap(keepUserCentered: $keepUserCentered) {
            UserAnnotation()
            if !recorder.route.isEmpty {
                MapPolyline(coordinates: recorder.route, contourStyle: .geodesic)
                    .stroke(.accent.resolve(in: environment), style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
        }
        .toolbar(content: toolbarContent)
        .overlay(alignment: .top, content: finishedWorkoutCard)
        .safeAreaInset(edge: .bottom, content: informationCard)
        .ignoresBottomSafeAreaOnIOS26OrLater()
        .overlay {
            if permissionNoticeIsPresented {
                RecordingPermissionNotice(dismiss: dismissPermissionNotice)
                    .transition(.opacity)
            }
        }
        .onChange(of: requiredPermissionsMissing, initial: true) { _, isMissing in
            guard isMissing else { return }
            permissionNoticeIsPresented = true
        }
        .interactiveDismissDisabled(recorder.status.isCollectingData)
        .presentationDragIndicator(recorder.status.isCollectingData ? .hidden : .visible)
        .alert(error?.localizedDescription ?? .init(localized: "error"), isPresented: errorIsPresented) {
            Button("ok") {}
        }
    }

    @ViewBuilder
    private func finishedWorkoutCard() -> some View {
        ZStack {
            if finishedWorkoutID != nil {
                SavedWorkoutNotice(
                    open: openFinishedWorkout,
                    delete: deleteFinishedWorkout,
                    dismiss: dismissFinishedWorkoutNotice
                )
                .padding(.regular)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.default, value: finishedWorkoutID)
        .task(id: finishedWorkoutID) {
            guard finishedWorkoutID != nil else { return }
            do {
                try await Task.sleep(for: .seconds(10))
                dismissFinishedWorkoutNotice()
            } catch {}
        }

    }

    @ViewBuilder
    private func informationCard() -> some View {
        let verticalPadding: Spacing = if #available(iOS 26, *) { .large } else { .regular }
        let recordingButtonPadding: Spacing? = if #available(iOS 26, *) { .small } else { .none }
        VStack(spacing: .regular) {
            HStack(spacing: .regular) {
                Menu {
                    Picker("recording_workout_type", selection: workoutTypeBinding) {
                        ForEach(WorkoutType.allCases, id: \.rawValue) { type in
                            Text(type.description).tag(type)
                        }
                    }
                } label: {
                    HStack(spacing: .extraSmall) {
                        Text(recorder.workoutType.description).font(.title)
                        Image(systemName: "chevron.down").font(.headline)
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                HStack(spacing: .extraSmall) {
                    Circle().fill(recorder.status.color)
                        .frame(width: 8)
                    Text(recorder.status.description)
                        .font(.footnote)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .compatibleRegularGlassEffect(in: .capsule)
                .backgroundStyle(.background.secondary)
            }
            .bold()
            
            LazyVGrid(columns: [.init(), .init()], alignment: .leading, spacing: .regular) {
                WorkoutMetricLabeledContent(
                    verbatim: WorkoutMetric.distance.description,
                    metricValue: .longDistanceMeasurement(recorder.distance)
                )
                WorkoutMetricLabeledContent(
                    verbatim: WorkoutMetric.activeDuration.description,
                    metricValue: duration
                )
                if recorder.workoutType == .cycling || recorder.workoutType == .skating {
                    WorkoutMetricLabeledContent(
                        verbatim: .init(localized: "speed"),
                        metricValue: .speedMeasurement(recorder.speed)
                    )
                } else {
                    WorkoutMetricLabeledContent(
                        verbatim: WorkoutMetric.pace.description,
                        metricValue: .paceMeasurement(recorder.speed)
                    )
                }
                WorkoutMetricLabeledContent(
                    verbatim: WorkoutMetric.energy.description,
                    metricValue: .energyMeasurement(recorder.energy)
                )
            }
            .monospacedDigit()
            .labeledContentStyle(.metric)
            
            RecordingButtons(
                isRecording: recorder.status.isCollectingData,
                isPaused: recorder.status == .paused(manual: true),
                startAction: startAction,
                endAction: endAction,
                pauseAction: pauseAction,
                resumeAction: resumeAction
            )
            .padding(recordingButtonPadding?.rawValue ?? .zero)
        }
        .padding(.horizontal, .large)
        .padding(.vertical, verticalPadding)
        .background { MapOverlayBackground() }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if !keepUserCentered {
            ToolbarItem(placement: .primaryAction) {
                keepUserCenteredButton
                    .labelStyle(.titleAndIcon)
            }
        }
        ToolbarItem(placement: .cancellationAction) {
            if recorder.status.isCollectingData {
                Menu {
                    Button("recording_minimize", systemImage: "arrow.down.right.and.arrow.up.left", action: dismiss.callAsFunction)
                    Button("recording_end", systemImage: "stop.fill") {
                        errorHandledAsyncAction {
                            try await endRecording()
                            dismiss()
                        }
                    }
                    Button("discard", systemImage: "trash", role: .destructive) {
                        errorHandledAsyncAction {
                            _ = try await recorder.discardRecording()
                            dismiss()
                        }
                    }
                } label: {
                    closeButton
                }
            } else {
                closeButton
            }
        }
    }
    
    @ViewBuilder private var keepUserCenteredButton: some View {
        let button = Button {
            withAnimation {
                keepUserCentered = true
            }
        } label: {
            HStack {
                Image(systemName: "location.fill.viewfinder")
                Text("center")
            }
            .font(.headline)
            .padding(.horizontal, .extraSmall)
        }
        .tint(.primary)
        if #available(iOS 26.0, *) {
            button
        } else {
            button
                .buttonStyle(.bordered)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    @ViewBuilder private var closeButton: some View {
        let button = Button("close", systemImage: "xmark", action: dismiss.callAsFunction)
            .labelStyle(.iconOnly)
            .tint(.primary)
        if #available(iOS 26.0, *) {
            button
                .font(.title2)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            button
                .font(.title)
                .symbolVariant(.circle.fill)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    // MARK: Actions
    
    private func errorHandledAsyncAction(_ action: @escaping () async throws -> Void) {
        Task {
            do {
                try await action()
            } catch {
                self.error = error
            }
        }
    }
    
    private func dismissPermissionNotice() {
        withAnimation {
            permissionNoticeIsPresented = false
        }
    }

    private func startAction() {
        errorHandledAsyncAction { try await recorder.startRecording() }
    }
    
    private func endAction() {
        errorHandledAsyncAction(endRecording)
    }
    
    private func endRecording() async throws {
        guard let workoutID = try await recorder.endRecording()?.id else { return }
        finishedWorkoutID = workoutID
        guard let count = try? modelContext.nativeWorkoutCount() else { return }
#if !RELEASE
        userPreferences.registerCompletedWorkout(nativeWorkoutCount: count)
#endif
        guard count > Self.reviewRequestWorkoutThreshold else { return }
        requestReview()
    }
    
    private func pauseAction() {
        errorHandledAsyncAction { try await recorder.pauseRecording() }
    }
    
    private func resumeAction() {
        errorHandledAsyncAction { try await recorder.resumeRecording() }
    }

    private func openFinishedWorkout() {
        guard let finishedWorkoutID else { return }
        dismissFinishedWorkoutNotice()
        router.open([WorkoutDetailRoute(id: finishedWorkoutID)])
    }

    private func deleteFinishedWorkout() {
        guard let finishedWorkoutID else { return }
        dismissFinishedWorkoutNotice()
        errorHandledAsyncAction {
            try await core.delete(workoutWithIdentifier: finishedWorkoutID)
        }
    }

    private func dismissFinishedWorkoutNotice() {
        finishedWorkoutID = nil
    }
}
