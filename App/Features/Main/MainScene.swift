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

import OutRunCore
import SwiftData
import SwiftUI
import TFRouting

struct MainScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(WorkoutRecorder.self) private var recorder
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(Router.self) private var router
    @Query private var finishedWorkouts: [Workout]
    @State private var largeTitleVisible: Bool?
    
    private var userName: String { core.user?.name ?? .init(localized: "user_name_fallback") }
    
    var body: some View {
        RouterHost(node: router.root) {
            GeometryReader { proxy in
                ScrollView {
                    container {
                        listGreetingView
                        if finishedWorkouts.isEmpty {
                            emptyWorkoutsView.frame(maxHeight: .infinity)
                        } else {
                            if userPreferences.donationPromptDue {
                                donationPromptCard
                            }
                            workoutCards
                            if finishedWorkouts.count > 3 {
                                calendarLink
                            }
                        }
                    }
                    .padding(.horizontal, .regular)
                    .frame(height: finishedWorkouts.isEmpty ? proxy.frame(in: .local).height : .none)
                }
            }
            .backgroundStyle(Color(.secondarySystemGroupedBackground))
            .background(Color(.systemGroupedBackground))
            .customBottomSafeAreaBar(content: bottomSafeAreaBarContent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .onAppear {
                guard core.recorder?.status == .recording else { return }
                showRecordingScene()
            }
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
    
    @ViewBuilder private var emptyWorkoutsView: some View {
        Image("illustration")
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
    
    @ViewBuilder private var donationPromptCard: some View {
        DonationPromptCard(action: showTipJar, dismiss: dismissDonationPrompt)
            .transition(unsafe .opacity.combined(with: .scale(scale: 0.95)))
    }
    
    @ViewBuilder private var calendarLink: some View {
        Button(action: showCalendarScene) {
            HStack(spacing: .small) {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(.tint)
                Text("browse_in_calendar")
                    .fontWeight(.medium)
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .fontWeight(.semibold)
            }
            .padding(.regular)
            .background()
            .clipShape(.rect(cornerRadius: .regular))
        }
        .buttonStyle(.plain)
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("calendar", systemImage: "calendar", action: showCalendarScene)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button("settings", systemImage: "gear", action: showSettingsScene)
        }
        ToolbarItem(placement: .principal) {
            greetingView
                .opacity(largeTitleVisible ?? true ? 0 : 1)
                .offset(y: largeTitleVisible ?? true ? Spacing.small.rawValue : 0)
                .animation(.spring(duration: 0.1), value: largeTitleVisible)
        }
    }
    
    @ViewBuilder
    private func container(@ViewBuilder _ content: () -> some View) -> some View {
        if finishedWorkouts.isEmpty {
            VStack(spacing: .regular, content: content)
        } else {
            LazyVStack(spacing: .regular, content: content)
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
            HStack {
                ActionButton("record_workout_action", action: showRecordingScene)
                ActionButton("add", systemImage: "plus", prominent: false, maxWidth: nil, action: showAddWorkoutScene)
                    .labelStyle(.iconOnly)
            }
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
    
    private func dismissDonationPrompt() {
        withAnimation {
            userPreferences.dismissDonationPrompt()
        }
    }
    
    private func showTipJar() {
        dismissDonationPrompt()
        router.open([SettingsRoute(), SettingsPageRoute.tipJar])
    }
    
    private func showRecordingScene() {
        router.route(RecordingRoute())
    }
    
    private func showSettingsScene() {
        router.route(SettingsRoute())
    }
    
    private func showCalendarScene() {
        router.route(CalendarRoute())
    }
    
    private func showWorkoutDetailScene(for workoutID: Workout.ID) {
        router.route(WorkoutDetailRoute(id: workoutID))
    }
    
    private func showAddWorkoutScene() {
        router.route(WorkoutEditRoute(id: nil))
    }
}
