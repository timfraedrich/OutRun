import OutRunCore
import SwiftUI

struct WorkoutDetailView: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var error: Error?
    private let workout: any WorkoutProtocol
    
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
            .padding(.top, .extraLarge)
            .padding(.horizontal, .large)
        }
        .background()
        .overlay(alignment: .topTrailing, content: closeButtonContent)
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
    
    init(workout: any WorkoutProtocol) {
        self.workout = workout
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
    WorkoutDetailView(workout: PreviewConstants.runningWorkout)
}
