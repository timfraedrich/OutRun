import Charts
import Glur
import OutRunCore
import SwiftUI
import MapKit
import TFRouting

struct WorkoutDetailScene: View {
    
    @Environment(OutRunCore.self) private var core
    @Environment(UserPreferences.self) private var userPreferences
    @Environment(RouterNode.self) private var node
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var error: Error?
    @State private var confirmDelete: Bool = false
    @State private var sectionedRoute: CategorizedArray<Bool, any WorkoutRouteDataSampleProtocol>?
    @State private var sectionedHeartRates: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>?
    @State private var sectionedAltitudes: Calculation.SectionedValues<Float>?
    @State private var sectionedSpeeds: Calculation.SectionedValues<Float>?
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var metrics: SceneMetrics = SceneMetrics()
    @State private var resolvedTintColor: CGColor?
    @State private var backupTypeToShare: BackupType?
    @State private var exportProcess: BackupProcess?
    private let workout: any WorkoutProtocol
    private let addCloseButton: Bool
    private let chartHeight: CGFloat = 125
    
    private var showMap: Bool { !workout.route.isEmpty }
    private var mapHeight: CGFloat { metrics.size.height * 0.6 }
    private var overlapHeight: CGFloat { mapHeight / 3 }
    /// Identifies the workout revision and unit preferences the derived chart values were calculated for, so they can be recalculated when they change.
    private var derivedValuesSignature: String {
        "\(workout.lastEditDate.timeIntervalSinceReferenceDate)|\(userPreferences.safeAltitudeUnit().symbol)|\(userPreferences.safeSpeedUnit().symbol)"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: .zero) {
                if showMap, mapHeight > 0 {
                    mapHeader
                }
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
                    commentSection
                    metadataSection
                    actionSection
                }
                .backgroundStyle(Color(.secondarySystemGroupedBackground))
                .padding(.horizontal, .regular)
                .padding(.top, showMap && mapHeight > 0 ? -overlapHeight : nil)
            }
        }
        .onGeometryChange(for: SceneMetrics.self) { proxy in
            SceneMetrics(size: proxy.size, topSafeAreaInset: proxy.safeAreaInsets.top)
        } action: { newMetrics in
            metrics = newMetrics
        }
        .background {
            ResolveTintColorView { color in
                resolvedTintColor = color
            }
        }
        .background()
        .backgroundStyle(Color(.systemGroupedBackground))
        .ignoresSafeArea(.all, edges: showMap ? .top : [])
        .toolbar(content: toolbarContent)
        .closeToolbarItem(active: addCloseButton)
        .hiddenNavigationTitle("workout_detail_title")
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .compatibleScrollEffectHidden(for: .top)
        .backupExport([workout.id], of: $backupTypeToShare, process: $exportProcess)
        .backupProcessSheet(for: $exportProcess)
        .task(id: derivedValuesSignature) {
            let sortedPauses = workout.pauses.sorted(using: KeyPathComparator(\.startDate, order: .forward))
            let sortedRoute = workout.route.sorted(using: KeyPathComparator(\.timestamp, order: .forward))
            let sectionedRoute = Calculation.calculateSectionedSamples(
                from: sortedRoute,
                timestampKeyPath: \.timestamp,
                pauses: sortedPauses
            )
            self.sectionedRoute = sectionedRoute
            let sortedHeartRates = workout.heartRates.sorted(using: KeyPathComparator(\.timestamp, order: .forward))
            self.sectionedHeartRates = Calculation.calculateSectionedSamples(
                from: sortedHeartRates,
                timestampKeyPath: \.timestamp,
                pauses: sortedPauses
            )
            self.routeCoordinates = sectionedRoute.flatMap(\.elements).map(\.coordinate)
            self.sectionedAltitudes = Calculation.calculateSectionedValues(
                from: sectionedRoute,
                for: \.validatedAltitude,
                and: \.timestamp,
                sourceUnit: .meters,
                destinationUnit: userPreferences.safeAltitudeUnit()
            )
            self.sectionedSpeeds = Calculation.calculateSectionedValues(
                from: sectionedRoute,
                for: \.validatedSpeed,
                and: \.timestamp,
                sourceUnit: .metersPerSecond,
                destinationUnit: userPreferences.safeSpeedUnit()
            )
        }
    }
    
    @ViewBuilder private var mapHeader: some View {
        Group {
            if let resolvedTintColor {
                StaticWorkoutMap(
                    identifier: workout.id,
                    coordinates: routeCoordinates,
                    tintColor: resolvedTintColor,
                    insets: .init(top: metrics.topSafeAreaInset, leading: .zero, bottom: overlapHeight, trailing: .zero)
                )
                .ignoresSafeArea()
                .glur(radius: 24, offset: 2 / 3, interpolation: 1 / 2, noise: 0.0)
                .mask {
                    VStack(spacing: .zero) {
                        Rectangle()
                        BackgroundBlackoutGradient(startPoint: .bottom, endPoint: .top).frame(height: overlapHeight)
                    }
                }
                .visualEffect { [mapHeight] content, proxy in
                    let yOffset = proxy.frame(in: .scrollView).minY
                    let progress = mapHeight > 0 ? yOffset / mapHeight : 0
                    return content
                        .scaleEffect(1 + max(0, progress), anchor: .bottom)
                        .offset(y: -min(0, yOffset))
                        .opacity(1 + min(0, progress))
                        .blur(radius: 10 * -min(0, progress))
                }
            }
        }
        .frame(height: mapHeight)
        .onTapGesture(perform: openMap)
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
            section("heart_rate") {
                metricGrid(with: [.averageHeartRate, .maximumHeartRate])
                LabeledContent("heart_rate") {
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
        if workout.energy != nil {
            section("workout_detail_section_energy") {
                metricGrid(with: [.energy, .energyPerMinute])
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
        Group {
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
        .multilineTextAlignment(.trailing)
    }
    
    @ViewBuilder private var actionSection: some View {
        VStack(spacing: .regular) {
            ActionButton("edit", systemImage: "pencil", prominent: false, action: edit)
            ActionButton("delete", systemImage: "trash") {
                confirmDelete = true
            }
            .tint(.red)
            .errorPopover($error)
            .confirmationDialog("workout_detail_delete_confirmation_title", isPresented: $confirmDelete) {
                Button("delete", role: .destructive, action: delete)
            } message: {
                Text("workout_detail_delete_confirmation_message")
            }
        }
        .padding(.regular)
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu("share", systemImage: "square.and.arrow.up") {
                ForEach(BackupType.exportableCases) { type in 
                    Button("\(Text(type.titleKey)) (.\(type.fileExtension))") {
                        backupTypeToShare = type
                    }
                }
            }
        }
    }
    
    init(workout: any WorkoutProtocol, addCloseButton: Bool = true) {
        self.workout = workout
        self.addCloseButton = addCloseButton
    }
    
    private func edit() {
        node.route(WorkoutEditRoute(id: workout.id))
    }
    
    private func openMap() {
        node.route(WorkoutMapRoute(id: workout.id))
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
    
    /// The container geometry the layout depends on. Kept in state so that geometry updates during the sheet's
    /// presentation and dismissal transitions don't rebuild the scroll content on every frame.
    private struct SceneMetrics: Equatable, Sendable {
        var size: CGSize = .zero
        var topSafeAreaInset: CGFloat = .zero
    }
}

#Preview {
    NavigationStack {
        WorkoutDetailScene(workout: PreviewConstants.runningWorkout)
    }
}
