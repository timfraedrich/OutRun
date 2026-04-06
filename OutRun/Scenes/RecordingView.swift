import CoreLocation
import OutRunCore
import SwiftData
import SwiftUI

struct RecordingView: View {
    
    @Environment(OutRunCore.self) private var core: OutRunCore
    @Environment(\.dismiss) private var dismiss
    @Bindable private var recorder: WorkoutRecorder
    @State private var error: Error?
    
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
        WorkoutRouteMap(coordinates: recorder.route, strokeColor: .accent, showUserLocation: true)
            .safeAreaInset(edge: .bottom, content: informationCard)
            .overlay(alignment: .topTrailing, content: closeButtonContent)
            .alert(error?.localizedDescription ?? "Error", isPresented: errorIsPresented) {
                Button("Ok") {}
            }
    }
    
    @ViewBuilder
    private func informationCard() -> some View {
        VStack(spacing: .regular) {
            HStack(spacing: .regular) {
                Menu {
                    Picker("Workout Type", selection: workoutTypeBinding) {
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
                Spacer()
                HStack(spacing: .extraSmall) {
                    Circle().fill(recorder.status.color)
                        .frame(width: 8)
                    Text(recorder.status.description)
                        .font(.footnote)
                        .textCase(.uppercase)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.background.secondary)
                .clipShape(.capsule)
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
                WorkoutMetricLabeledContent(
                    verbatim: WorkoutMetric.pace.description,
                    metricValue: .paceMeasurement(recorder.speed)
                )
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(content: MapOverlayBackground.init)
    }
    
    @ViewBuilder
    private func closeButtonContent() -> some View {
        let button = Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
            .labelStyle(.iconOnly)
            .tint(.primary)
        if #available(iOS 26.0, *) {
            button
                .font(.title2.weight(.medium))
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
                .padding(24)
        } else {
            button
                .font(.title)
                .symbolVariant(.circle.fill)
                .symbolRenderingMode(.hierarchical)
                .padding(16)
        }
    }
    
    // MARK: Init
    
    init(recorder: WorkoutRecorder) {
        self.recorder = recorder
    }
    
    // MARK: Actions
    
    private func startAction() {
        Task {
            do {
                try await recorder.startRecording()
            } catch {
                self.error = error
            }
        }
    }
    
    private func endAction() {
        Task {
            do {
                _ = try await recorder.endRecording()
            } catch {
                self.error = error
            }
        }
    }
    
    private func pauseAction() {
        Task {
            do {
                try await recorder.pauseRecording()
            } catch {
                self.error = error
            }
        }
    }
    
    private func resumeAction() {
        Task {
            do {
                try await recorder.resumeRecording()
            } catch {
                self.error = error
            }
        }
    }
}

extension WorkoutRecorderStatus {
    var color: Color {
        switch self {
        case .idle: .green
        case .recording: .red
        case .failed, .initializing, .paused: .gray
        }
    }
}
