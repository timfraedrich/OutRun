import Charts
import OutRunCore
import SwiftUI

struct WorkoutDetailScene: View {
    
    private typealias ValueSamples<V: Numeric & Comparable & Plottable> = CategorizedArray<Bool, SampleChart<V>.Sample>
    
    @Environment(OutRunCore.self) private var core
    @Environment(\.dismiss) private var dismiss
    @State private var error: Error?
    @State private var sectionedRoute: CategorizedArray<Bool, any WorkoutRouteDataSampleProtocol>?
    @State private var sectionedHeartRates: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>?
    private let workout: any WorkoutProtocol
    private let addCloseButton: Bool
    private let chartHeight: CGFloat = 125
    
    private var sectionedAltitudes: ValueSamples<Float>? { sectionedRouteSamples(for: \.altitude) }
    private var sectionedSpeeds: ValueSamples<Float>? { sectionedRouteSamples(for: \.speed) }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .large) {
                header
                distanceSection
                timeSection
                heartRateSection
                speedSection
                energySection
                routeSection
                actionSection
            }
            .backgroundStyle(.secondaryBackground)
            .padding(.horizontal, .regular)
        }
        .background()
        .toolbar(content: toolbarContent)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .compatibleScrollEffectHidden(for: .top)
        .backgroundStyle(.primaryBackground)
        .labeledContentStyle(.metric)
        .task {
            let sortedPauses = workout.pauses.sorted(using: KeyPathComparator(\.startDate, order: .forward))
            let sortedRoute = workout.route.sorted(using: KeyPathComparator(\.timestamp, order: .forward))
            self.sectionedRoute = Calculation.calculateSectionedSamples(
                from: sortedRoute,
                timestampKeyPath: \.timestamp,
                pauses: sortedPauses
            )
            let sortedHeartRates = workout.heartRates.sorted(using: KeyPathComparator(\.timestamp, order: .forward))
            self.sectionedHeartRates = Calculation.calculateSectionedSamples(
                from: sortedHeartRates,
                timestampKeyPath: \.timestamp,
                pauses: sortedPauses
            )
        }
    }
    
    @ViewBuilder private var header: some View {
        WorkoutHeaderLabeledContent(workout: workout)
            .labeledContentStyle(.metric(size: .large))
            .padding(.horizontal, .small)
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
            VStack(spacing: .regular, content: content)
                .padding(contentPadding)
                .background()
                .clipShape(.containerRelative)
                .containerShape(.rect(cornerRadius: .regular))
        }
    }
    
    @ViewBuilder
    private func metricGrid(with metrics: [WorkoutMetric]) -> some View {
        LazyVGrid(columns: [.init(alignment: .leading), .init(alignment: .leading)], alignment: .leading, spacing: .regular) {
            ForEach(metrics, id: \.hashValue) { metric in
                WorkoutMetricLabeledContent(metric, for: workout)
            }
        }
    }
    
    @ViewBuilder private var distanceSection: some View {
        section("Distance") {
            metricGrid(with: [.distance, .repetitions, .ascent, .descent])
            if let endDate = workout.endDate, let sectionedAltitudes {
                LabeledContent("Altitude") {
                    SampleChart("Altitude", sectionedSamples: sectionedAltitudes, dateRange: workout.startDate...endDate)
                        .frame(height: chartHeight)
                }
            }
        }
    }
    
    @ViewBuilder private var timeSection: some View {
        section("Time") {
            metricGrid(with: [.activeDuration, .pauseDuration, .pace, .startTime, .endTime])
        }
    }
    
    @ViewBuilder private var heartRateSection: some View {
        if let endDate = workout.endDate, let sectionedHeartRates, !sectionedHeartRates.isEmpty {
            section("Heart Rate") {
                metricGrid(with: [.averageHeartRate, .maximumHeartRate])
                HeartRateChart(sectionedSamples: sectionedHeartRates, dateRange: workout.startDate...endDate)
            }
        }
    }
    
    @ViewBuilder private var speedSection: some View {
        section("Speed") {
            metricGrid(with: [.averageSpeed, .topSpeed])
            if let endDate = workout.endDate, let sectionedSpeeds {
                LabeledContent("Speed") {
                    SampleChart("Speed", sectionedSamples: sectionedSpeeds, dateRange: workout.startDate...endDate)
                        .frame(height: chartHeight)
                }
            }
        }
    }
    
    @ViewBuilder private var energySection: some View {
        section("Energy") {
            metricGrid(with: [.energy, .energyPerMinute])
        }
    }
    
    @ViewBuilder private var routeSection: some View {
        if !workout.route.isEmpty {
            section("Route", contentPadding: .small) {
                StaticWorkoutMap(identifier: workout.id, coordinates: workout.route.map(\.coordinate), accentColor: .accent)
                    .frame(height: 300)
                    .clipShape(.containerRelative)
            }
        }
    }
    
    @ViewBuilder private var actionSection: some View {
        ActionButton("Delete", action: delete)
            .errorPopover($error)
            .tint(.red)
            .padding(.regular)
    }
    
    @ViewBuilder
    private func toolbarContent() -> some View {
        if addCloseButton {
            Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
        }
    }
    
    init(workout: any WorkoutProtocol, addCloseButton: Bool = true) {
        self.workout = workout
        self.addCloseButton = addCloseButton
    }
    
    private func sectionedRouteSamples<V>(for keyPath: KeyPath<any WorkoutRouteDataSampleProtocol, V>) -> ValueSamples<V>? {
        guard let sectionedRoute else { return nil }
        let sectionedAltitudes: ValueSamples<V> = sectionedRoute.compactMap { active, samples in
            let filteredValues = samples.compactMap { $0[keyPath: keyPath] >= 0 ? ($0.timestamp, $0[keyPath: keyPath]) : nil }
            guard !filteredValues.isEmpty else { return nil }
            return (active, filteredValues)
        }
        guard !sectionedAltitudes.isEmpty else { return nil }
        return sectionedAltitudes
    }
    
    private func delete() {
        Task {
            do {
                try await core.delete(workoutWithIdentifier: workout.id)
                dismiss()
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailScene(workout: PreviewConstants.runningWorkout)
    }
}
