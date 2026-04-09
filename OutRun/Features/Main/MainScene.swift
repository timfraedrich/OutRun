import OutRunCore
import SwiftData
import SwiftUI

struct MainScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(MainRouter.self) private var mainRouter
    @Query private var finishedWorkouts: [Workout]
    @State private var largeTitleVisible: Bool?
    
    private var userName: String { core.user?.name ?? "User" }
    
    var body: some View {
        @Bindable var mainRouter = mainRouter
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: .regular) {
                    listGreetingView
                    grantPermissionViews
                    if finishedWorkouts.isEmpty {
                        emptyWorkoutsView
                    } else {
                        workoutCards
                    }
                    calendarLink
                }
                .padding(.horizontal, .regular)
            }
            .background()
            .customBottomSafeAreaBar(content: bottomSafeAreaBarContent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .sheet(item: $mainRouter.currentSheet) { sheet in
                switch sheet {
                case .calendar:
                    CalendarScene()
                case .recording:
                    if let recorder = core.recorder {
                        RecordingScene(recorder: recorder)
                    }
                case .settings:
                    SettingsScene()
                case .workoutDetails(let workoutID):
                    NavigationStack {
                        QueriedWorkoutDetailScene(id: workoutID)
                    }
                }
            }
        }
        .onAppear {
            guard core.recorder?.status == .recording else { return }
            showRecordingScene()
        }
    }
    
    @ViewBuilder private var greetingView: some View {
        GreetingText(name: userName).bold()
    }
    
    @ViewBuilder private var listGreetingView: some View {
        greetingView
            .font(.largeTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(largeTitleVisible ?? true ? 1 : 0)
            .animation(.spring(duration: 0.1), value: largeTitleVisible)
            .onScrollVisibilityChange { isVisible in
                guard largeTitleVisible != nil || isVisible else { return }
                largeTitleVisible = isVisible
            }
    }
    
    @ViewBuilder private var grantPermissionViews: some View {
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
    }
    
    @ViewBuilder private var emptyWorkoutsView: some View {
        Image(R.image.illustration)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(.extraLarge)
    }

    @ViewBuilder private var workoutCards: some View {
        ForEach(finishedWorkouts) { workout in
            let isFirstCard = workout.id == finishedWorkouts.first?.id
            WorkoutCard(workout: workout)
                .workoutCardStyle(isFirstCard ? AnyWorkoutCardStyle(.latest) : AnyWorkoutCardStyle(.list))
                .onTapGesture { showWorkoutDetailScene(for: workout.id) }
        }
    }
    
    @ViewBuilder private var calendarLink: some View {
        Button {
            mainRouter.currentSheet = .calendar
        } label: {
            HStack(spacing: .small) {
                Image(systemName: "calendar")
                    .font(.title3)
                Text("Browse in Calendar")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
            .padding(.regular)
            .background(.secondaryBackground)
            .clipShape(.rect(cornerRadius: .regular))
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Settings", systemImage: "gear", action: showSettingsScene)
                .labelStyle(.iconOnly)
        }
        ToolbarItem(placement: .principal) {
            greetingView
                .opacity(largeTitleVisible ?? true ? 0 : 1)
                .offset(y: largeTitleVisible ?? true ? Spacing.small.rawValue : 0)
                .animation(.spring(duration: 0.1), value: largeTitleVisible)
        }
    }
    
    @ViewBuilder
    private func bottomSafeAreaBarContent() -> some View {
        if recorder.status.isCollectingData {
            WorkoutInProgressButton(
                workoutType: recorder.workoutType,
                distance: recorder.distance,
                duration: recorder.duration,
                action: showRecordingScene
            )
        } else {
            ActionButton(verbatim: "Record a Workout", action: showRecordingScene)
        }
    }
    
    init() {
        var descriptor = FetchDescriptor<Workout>(
            predicate: #Predicate<Workout> { $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 13
        descriptor.propertiesToFetch = [\.rawType, \.startDate, \.endDate, \.distance, \.energy]
        descriptor.relationshipKeyPathsForPrefetching = [\.pauses]
        self._finishedWorkouts = Query(descriptor)
    }
    
    private func showRecordingScene() {
        mainRouter.currentSheet = .recording
    }
    
    private func showSettingsScene() {
        mainRouter.currentSheet = .settings
    }
    
    private func showWorkoutDetailScene(for workoutID: Workout.ID) {
        mainRouter.currentSheet = .workoutDetails(id: workoutID)
    }
}
