import CoreLocation
import MapKit
import OutRunCore
import SwiftData
import SwiftUI

struct RecordingScene: View {
    
    @Environment(\.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @Environment(OutRunCore.self) private var core
    @Environment(WorkoutRecorder.self) private var recorder
    
    @State private var keepUserCentered: Bool = true
    @State private var error: Error?
    
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
    
    private var workoutTypeBinding: Binding<WorkoutType> {
        .init(
            get: { recorder.workoutType },
            set: { type in
                Task {
                    try await recorder.changeWorkoutType(to: type)
                }
            }
        )
    }
    
    // MARK: Views
    
    var body: some View {
        @Bindable var recorder = recorder
        WorkoutMap(keepUserCentered: $keepUserCentered, padding: padding) {
            UserAnnotation()
            if !recorder.route.isEmpty {
                MapPolyline(coordinates: recorder.route, contourStyle: .geodesic)
                    .stroke(.accent.resolve(in: environment), style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
        }
        .safeAreaInset(edge: .top, content: topBarContent)
        .safeAreaInset(edge: .bottom, content: informationCard)
        .ignoresBottomSafeAreaOnIOS26OrLater()
        .toolbarVisibility(.hidden, for: .navigationBar)
        .interactiveDismissDisabled(recorder.status.isCollectingData)
        .alert(error?.localizedDescription ?? .init(localized: "error"), isPresented: errorIsPresented) {
            Button("ok") {}
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
        .background(content: MapOverlayBackground.init)
    }
    
    @ViewBuilder
    private func topBarContent() -> some View {
        HStack {
            if !keepUserCentered {
                keepUserCenteredButton
            }
            Spacer()
            if recorder.status.isCollectingData {
                Menu {
                    Button("recording_minimize", systemImage: "arrow.down.right.and.arrow.up.left", action: dismiss.callAsFunction)
                    Button("recording_end", systemImage: "stop.fill", role: .destructive) {
                        errorHandledAsyncAction {
                            _ = try await recorder.endRecording()
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
        .padding([.horizontal, .top], padding)
    }
    
    @ViewBuilder private var keepUserCenteredButton: some View {
        let button = Button("center", systemImage: "location.fill.viewfinder") {
            withAnimation {
                keepUserCentered = true
            }
        }
        .tint(.primary)
        if #available(iOS 26.0, *) {
            button
                .font(.headline)
                .frame(height: 44)
                .padding(.horizontal, .regular)
                .glassEffect(.regular.interactive(), in: .capsule)
        } else {
            button
                .buttonStyle(.bordered)
                .font(.headline)
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
    
    private func startAction() {
        errorHandledAsyncAction { try await recorder.startRecording() }
    }
    
    private func endAction() {
        errorHandledAsyncAction { _ = try await recorder.endRecording() }
    }
    
    private func pauseAction() {
        errorHandledAsyncAction { try await recorder.pauseRecording() }
    }
    
    private func resumeAction() {
        errorHandledAsyncAction { try await recorder.resumeRecording() }
    }
}
