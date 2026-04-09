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
            VStack(alignment: .leading, spacing: .extraLarge) {
                
                WorkoutHeaderLabeledContent(workout: workout).labeledContentStyle(.metric(size: .large))
                
                metricSection("Distance", metrics: [.distance, .repetitions, .ascent, .descent])
                metricSection("Time", metrics: [.activeDuration, .pauseDuration, .pace, .startTime, .endTime])
                metricSection("Speed", metrics: [.averageSpeed, .topSpeed])
                metricSection("Energy", metrics: [.energy, .energyPerMinute])
                routeSection
                
                ActionButton(verbatim: "Delete", action: delete)
                    .errorPopover($error)
                    .tint(.red)
            }
            .padding(.horizontal, .large)
        }
        .background()
        .toolbar(content: closeButtonContent)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .backgroundStyle(.secondaryBackground)
        .labeledContentStyle(.metric)
    }
    
    @ViewBuilder
    private func metricSection(_ title: String, metrics: [WorkoutMetric]) -> some View {
        VStack(alignment: .leading, spacing: .regular) {
            Text(title).font(.headline).foregroundStyle(.tint)
            LazyVGrid(columns: [.init(alignment: .leading), .init(alignment: .leading)], alignment: .leading, spacing: .regular) {
                ForEach(metrics, id: \.hashValue) { metric in
                    WorkoutMetricLabeledContent(metric, for: workout)
                }
            }
        }
    }
    
    @ViewBuilder private var routeSection: some View {
        VStack(alignment: .leading, spacing: .regular) {
            Text("Route").font(.headline).foregroundStyle(.tint)
            WorkoutRouteMap(workout: workout, strokeColor: .accent)
                .frame(height: 300)
                .clipShape(.rect(cornerRadius: .regular))
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
