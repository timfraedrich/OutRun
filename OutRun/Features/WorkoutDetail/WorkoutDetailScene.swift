import OutRunCore
import SwiftUI

struct WorkoutDetailScene: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var error: Error?
    private let workout: any WorkoutProtocol
    private let addCloseButton: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .large) {
                
                WorkoutHeaderLabeledContent(workout: workout)
                    .labeledContentStyle(.metric(size: .large))
                    .padding(.horizontal, .small)
                
                metricSection("Distance", metrics: [.distance, .repetitions, .ascent, .descent])
                metricSection("Time", metrics: [.activeDuration, .pauseDuration, .pace, .startTime, .endTime])
                metricSection("Speed", metrics: [.averageSpeed, .topSpeed])
                metricSection("Energy", metrics: [.energy, .energyPerMinute])
                routeSection
                
                ActionButton(verbatim: "Delete", action: delete)
                    .errorPopover($error)
                    .tint(.red)
            }
            .backgroundStyle(.secondaryBackground)
            .padding(.horizontal, .regular)
        }
        .background()
        .toolbar(content: closeButtonContent)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .compatibleScrollEffectHidden(for: .top)
        .backgroundStyle(.primaryBackground)
        .labeledContentStyle(.metric)
    }
    
    @ViewBuilder
    private func section<C: View>(
        _ titleKey: LocalizedStringKey,
        contentPadding: Spacing = .regular,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: .small) {
            Text(titleKey)
                .font(.headline)
                .padding(.horizontal, .regular)
            content()
                .padding(contentPadding)
                .background()
                .clipShape(.containerRelative)
                .containerShape(.rect(cornerRadius: .regular))
        }
    }
    
    @ViewBuilder
    private func metricSection(_ titleKey: LocalizedStringKey, metrics: [WorkoutMetric]) -> some View {
        section(titleKey) {
            LazyVGrid(columns: [.init(alignment: .leading), .init(alignment: .leading)], alignment: .leading, spacing: .regular) {
                ForEach(metrics, id: \.hashValue) { metric in
                    WorkoutMetricLabeledContent(metric, for: workout)
                }
            }
        }
    }
    
    @ViewBuilder private var routeSection: some View {
        section("Route", contentPadding: .small) {
            StaticWorkoutMap(identifier: workout.id, coordinates: workout.route.map(\.coordinate), accentColor: .accent)
                .frame(height: 300)
                .clipShape(.containerRelative)
        }
    }
    
    @ViewBuilder
    private func closeButtonContent() -> some View {
        if addCloseButton {
            Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
                .labelStyle(.iconOnly)
                .tint(.primary)
        }
    }
    
    init(workout: any WorkoutProtocol, addCloseButton: Bool = true) {
        self.workout = workout
        self.addCloseButton = addCloseButton
    }
    
    private func delete() {
        do {
            let identifer = workout.id
            try modelContext.delete(model: Workout.self, where: #Predicate { $0.id == identifer })
            try modelContext.save()
            dismiss()
        } catch {
            self.error = error
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailScene(workout: PreviewConstants.runningWorkout)
    }
}
