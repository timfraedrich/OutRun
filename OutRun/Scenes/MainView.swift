import OutRunCore
import SwiftData
import SwiftUI

struct MainView: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(UserPreferences.self) private var userPreferences
    @Query private var finishedWorkouts: [Workout]
    @State private var largeTitleVisible: Bool?
    @State private var recordingViewIsPresented: Bool = false
    @State private var settingsSceneIsPresented: Bool = false
    @State private var detailWorkout: Workout?
    
    private var userName: String {
        core.user?.name ?? "User"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: .regular) {
                    greetingView
                        .font(.largeTitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(largeTitleVisible ?? true ? 1 : 0)
                        .animation(.spring(duration: 0.1), value: largeTitleVisible)
                        .onScrollVisibilityChange { isVisible in
                            guard largeTitleVisible != nil || isVisible else { return }
                            largeTitleVisible = isVisible
                        }
                    
                    if let recorder = core.recorder, !recorder.missingPermissions.isEmpty {
                        ForEach(Array(recorder.missingPermissions), id: \.hashValue) { permission in
                            Button("Grant \(permission.description) Permission") {
                                Task {
                                    try await recorder.requestAuthorization(for: permission)
                                }
                            }
                            .tint(permission.isRequired ? .red : .yellow)
                        }
                    }
                    
                    if finishedWorkouts.isEmpty {
                        Image(R.image.illustration)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(.extraLarge)
                    } else {
                        WorkoutCard(workout: finishedWorkouts[0])
                            .workoutCardStyle(.last)
                            .onTapGesture { detailWorkout = finishedWorkouts[0] }
                        ForEach(finishedWorkouts[1...]) { workout in
                            WorkoutCard(workout: workout).onTapGesture { detailWorkout = workout }
                        }
                    }
                }
                .padding(.horizontal, .regular)
            }
            .background()
            .safeAreaInset(edge: .bottom, content: bottomSafeAreaInsetContent)
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $recordingViewIsPresented) {
                if let recorder = core.recorder {
                    RecordingView(recorder: recorder)
                }
            }
            .sheet(isPresented: $settingsSceneIsPresented, content: {
                if let userPreferences = core.userPreferences {
                    SettingsScene(userPreferences: userPreferences)
                }
            })
            .sheet(item: $detailWorkout) { workout in
                WorkoutDetailView(workout: workout)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gear") {
                        settingsSceneIsPresented = true
                    }
                    .labelStyle(.iconOnly)
                }
                ToolbarItem(placement: .principal) {
                    greetingView
                        .opacity(largeTitleVisible ?? true ? 0 : 1)
                        .offset(y: largeTitleVisible ?? true ? Spacing.small.rawValue : 0)
                        .animation(.spring(duration: 0.1), value: largeTitleVisible)
                }
            }
        }
        .onAppear {
            guard core.recorder?.status == .recording else { return }
            recordingViewIsPresented = true
        }
    }
    
    @ViewBuilder private var greetingView: some View {
        GreetingText(name: userName).bold()
    }
    
    @ViewBuilder
    private func bottomSafeAreaInsetContent() -> some View {
        Group {
            if recorder.status.isCollectingData {
                TrainingInProgressButton(workoutType: recorder.workoutType, distance: recorder.distance, duration: recorder.duration) {
                    recordingViewIsPresented = true
                }
            } else {
                ActionButton(verbatim: "Record a Workout") {
                    recordingViewIsPresented = true
                }
            }
        }
        .padding(.extraLarge)
        .background { BackgroundBlackoutGradient(startPoint: .top, endPoint: .center) }
    }
    
    init() {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 42
        descriptor.propertiesToFetch = [\.rawType, \.startDate, \.endDate, \.distance, \.energy]
        descriptor.relationshipKeyPathsForPrefetching = [\.pauses]
        self._finishedWorkouts = Query(descriptor)
    }
}

struct TrainingInProgressButton: View {
    
    let workoutType: WorkoutType
    let distance: Measurement<UnitLength>
    let duration: DynamicTimeInterval
    let action: () -> Void
    
    var body: some View {
        let button = Button(action: action) {
            HStack(spacing: .small) {
                WorkoutMetricText(metricValue: .type(.running)).bold()
                switch duration {
                case .constant(let timeInterval):
                    WorkoutMetricText(metricValue: .duration(timeInterval))
                case .increasing(let start, let offset):
                    WorkoutMetricText(metricValue: .increasingDuration(start, offset))
                }
                WorkoutMetricText(metricValue: .longDistanceMeasurement(distance))
                Spacer()
                let image = Image(systemName: "chevron.up.square.fill").font(.title3)
                if #available(iOS 26, *) {
                    image.foregroundStyle(.tint)
                } else {
                    image
                }
            }
        }
        .monospacedDigit()
        .controlSize(.large)
        if #available(iOS 26, *) {
            button.buttonStyle(.glass)
        } else {
            button.buttonStyle(.borderedProminent).buttonBorderShape(.roundedRectangle(radius: .regular))
        }
    }
}
