import Charts
import OutRunCore
import SwiftUI

struct WorkoutDetailScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(MainRouter.self) private var mainRouter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var error: Error?
    @State private var sectionedRoute: CategorizedArray<Bool, any WorkoutRouteDataSampleProtocol>?
    @State private var sectionedHeartRates: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>?
    private let workout: any WorkoutProtocol
    private let addCloseButton: Bool
    private let chartHeight: CGFloat = 125
    
    private var sectionedAltitudes: Calculation.SectionedValues<Float>? {
        Calculation.calculateSectionedValues(
            from: sectionedRoute,
            for: \.altitude,
            and: \.timestamp,
            sourceUnit: .meters,
            destinationUnit: userPreferences.safeAltitudeUnit()
        )
    }
    
    private var sectionedSpeeds: Calculation.SectionedValues<Float>? {
        Calculation.calculateSectionedValues(
            from: sectionedRoute,
            for: \.speed,
            and: \.timestamp,
            sourceUnit: .metersPerSecond,
            destinationUnit: userPreferences.safeSpeedUnit()
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .large) {
                Group {
                    header
                    distanceSection
                    timeSection
                    heartRateSection
                    speedSection
                    energySection
                }
                .labeledContentStyle(.metric)
                routeSection
                commentSection
                metadataSection
                actionSection
            }
            .backgroundStyle(.background.secondary)
            .padding(.horizontal, .regular)
        }
        .background()
        .toolbar(content: toolbarContent)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .compatibleScrollEffectHidden(for: .top)
        .backgroundStyle(.background)
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
        _ text: Text,
        contentPadding: Spacing = .regular,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: .small) {
            text
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
    private func section<C: View>(
        _ titleKey: LocalizedStringKey,
        contentPadding: Spacing = .regular,
        @ViewBuilder content: () -> C
    ) -> some View {
        section(Text(titleKey), contentPadding: contentPadding, content: content)
    }
    
    @ViewBuilder
    private func section<C: View>(
        verbatim title: String,
        contentPadding: Spacing = .regular,
        @ViewBuilder content: () -> C
    ) -> some View {
        section(Text(verbatim: title), contentPadding: contentPadding, content: content)
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
        section("workout_detail_section_distance") {
            metricGrid(with: [.distance, .repetitions, .ascent, .descent])
            if let endDate = workout.endDate, let sectionedAltitudes {
                LabeledContent("altitude") {
                    SampleChart("altitude", sectionedSamples: sectionedAltitudes, dateRange: workout.startDate...endDate)
                        .frame(height: chartHeight)
                }
            }
        }
    }
    
    @ViewBuilder private var timeSection: some View {
        section("workout_detail_section_time") {
            metricGrid(with: [.activeDuration, .pauseDuration, .pace, .startTime, .endTime])
        }
    }
    
    @ViewBuilder private var heartRateSection: some View {
        if let endDate = workout.endDate, let sectionedHeartRates, !sectionedHeartRates.isEmpty {
            section("workout_detail_section_heart_rate") {
                metricGrid(with: [.averageHeartRate, .maximumHeartRate])
                LabeledContent("workout_detail_section_heart_rate") {
                    HeartRateChart(sectionedSamples: sectionedHeartRates, dateRange: workout.startDate...endDate)
                        .frame(height: chartHeight)
                }
            }
        }
    }
    
    @ViewBuilder private var speedSection: some View {
        section("workout_detail_section_speed") {
            metricGrid(with: [.averageSpeed, .topSpeed])
            if let endDate = workout.endDate, let sectionedSpeeds {
                LabeledContent("speed") {
                    SampleChart("speed", sectionedSamples: sectionedSpeeds, dateRange: workout.startDate...endDate)
                        .frame(height: chartHeight)
                }
            }
        }
    }
    
    @ViewBuilder private var energySection: some View {
        section("workout_detail_section_energy") {
            metricGrid(with: [.energy, .energyPerMinute])
        }
    }
    
    @ViewBuilder private var routeSection: some View {
        if !workout.route.isEmpty {
            section("workout_detail_section_route", contentPadding: .small) {
                StaticWorkoutMap(identifier: workout.id, coordinates: workout.route.map(\.coordinate), accentColor: .accent)
                    .frame(height: 300)
                    .clipShape(.containerRelative)
            }
        }
    }
    
    @ViewBuilder private var commentSection: some View {
        if let comment = workout.comment {
            section("comment") {
                Text(comment).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder private var metadataSection: some View {
        section("metadata") {
            VStack(spacing: .regular) {
                LabeledContent("id", value: workout.id.uuidString)
                Divider()
                LabeledContent("created", value: workout.creationDate.formatted())
                Divider()
                LabeledContent("last_edited", value: workout.lastEditDate.formatted())
                Divider()
                LabeledContent("workout_source", value: workout.source.localized)
            }
        }
        ForEach(workout.serviceMappings, id: \.serviceIdentifier) { mapping in
            section(verbatim: WorkoutSource.syncService(identifier: mapping.serviceIdentifier).localized) {
                if let id = mapping.externalId {
                    LabeledContent("id", value: id)
                    Divider()
                }
                LabeledContent("sync_status") {
                    Label {
                        Text(mapping.syncStatus.localized)
                    } icon: {
                        Image(systemName: mapping.syncStatus.systemImage)
                    }
                    .foregroundStyle(mapping.syncStatus.color)
                }
                if let lastEditDateSynced = mapping.lastEditDateSynced {
                    Divider()
                    LabeledContent("last_synced", value: lastEditDateSynced.formatted())
                }
                if let urlString = mapping.externalUrl, let url = URL(string: urlString) {
                    Divider()
                    Button("sync_service_open_externally", systemImage: "link") {
                        openURL(url)
                    }
                }
            }
        }
    }
    
    @ViewBuilder private var actionSection: some View {
        VStack(spacing: .regular) {
            ActionButton("edit", systemImage: "pencil", prominent: false, action: edit)
            ActionButton("delete", systemImage: "trash", action: delete)
                .errorPopover($error)
                .tint(.red)
        }
        .padding(.regular)
    }
    
    @ViewBuilder
    private func toolbarContent() -> some View {
        if addCloseButton {
            Button("close", systemImage: "xmark", action: dismiss.callAsFunction)
        }
    }
    
    init(workout: any WorkoutProtocol, addCloseButton: Bool = true) {
        self.workout = workout
        self.addCloseButton = addCloseButton
    }
    
    private func edit() {
        mainRouter.currentSheet = .workoutEdit(id: workout.id)
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
