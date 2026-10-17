import CoreLocation
import MapKit
import OutRunCore
import SwiftData
import SwiftUI

struct WorkoutMapScene: View {
    
    @Environment(\.self) private var environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(UserPreferences.self) private var userPreferences
    
    @Namespace var mapScope
    
    @State private var sortedRoute: [WorkoutRouteDataSample] = []
    @State private var sectionedRoute: CategorizedArray<Bool, WorkoutRouteDataSample>?
    @State private var sectionedHeartRates: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>?
    @State private var sectionedAltitudes: Calculation.SectionedValues<Float>?
    @State private var sectionedSpeeds: Calculation.SectionedValues<Float>?
    @State private var dateRange: ClosedRange<Date>?
    @State private var selectedTimestamp: Date?
    @State private var selectedChartType: WorkoutChartMetric
    @State private var zoomLevel: ChartZoomLevel = .whole
    @State private var mapStyleSelection: MapStyleSelection = .standard
    @State private var error: Error?
    
    private let id: Workout.ID
    private let addCloseButton: Bool
    private let chartHeight: CGFloat = 180
    
    private var padding: Spacing = if #available(iOS 26, *) { .large } else { .regular }
    
    private var routeSections: [RouteSection] {
        guard let sectionedRoute else { return [] }
        return sectionedRoute.enumerated().compactMap { index, section in
            let coordinates = section.elements.map(\.coordinate)
            guard coordinates.count > 1 else { return nil }
            return RouteSection(id: index, active: section.category, coordinates: coordinates)
        }
    }
    
    private var selectedCoordinate: CLLocationCoordinate2D? {
        guard let selectedTimestamp, !sortedRoute.isEmpty else { return nil }
        let index = sortedRoute.binarySearch { $0.timestamp < selectedTimestamp }
        return sortedRoute[safeIndex: index]?.coordinate ?? sortedRoute.last?.coordinate
    }
    
    private var availableChartTypes: [WorkoutChartMetric] {
        guard let dateRange, dateRange.lowerBound < dateRange.upperBound else { return [] }
        var available: [WorkoutChartMetric] = []
        if sectionedSpeeds != nil { available.append(.speed) }
        if sectionedAltitudes != nil { available.append(.altitude) }
        if let hr = sectionedHeartRates, !hr.flatMap(\.elements).isEmpty { available.append(.heartRate) }
        return available
    }
    
    init(id: Workout.ID, metric: WorkoutChartMetric = .speed, addCloseButton: Bool) {
        self.id = id
        self.addCloseButton = addCloseButton
        self._selectedChartType = State(initialValue: metric)
    }
    
    var body: some View {
        WorkoutMap(
            keepUserCentered: .constant(false),
            style: mapStyleSelection.style
        ) {
            ForEach(routeSections) { section in
                let color: Color = section.active ? .accentColor : .gray.opacity(0.75)
                MapPolyline(coordinates: section.coordinates, contourStyle: .geodesic)
                    .stroke(color.resolve(in: environment), style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }
            if let coord = selectedCoordinate {
                Annotation("workout_map_selected_location", coordinate: coord) {
                    selectedLocationMarker
                }
                .annotationTitles(.hidden)
            }
        }
        .toolbar(content: toolbarContent)
        .closeToolbarItem(active: addCloseButton)
        .safeAreaInset(edge: .bottom, content: informationCard)
        .ignoresBottomSafeAreaOnIOS26OrLater()
        .errorAlert($error)
        .task(loadWorkout)
        .onChange(of: availableChartTypes) { _, newTypes in
            if !newTypes.isEmpty, !newTypes.contains(selectedChartType) {
                selectedChartType = newTypes[0]
            }
        }
    }
    
    @ViewBuilder private var selectedLocationMarker: some View {
        Circle()
            .fill(.tint)
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .shadow(radius: 2)
    }
    
    @ViewBuilder private var mapStyleMenu: some View {
        Menu {
            Picker("workout_map_style", selection: $mapStyleSelection) {
                ForEach(MapStyleSelection.allCases) { style in
                    Label(style.titleKey, systemImage: style.systemImage).tag(style)
                }
            }
        } label: {
            Label("workout_map_style", systemImage: mapStyleSelection.systemImage)
                .labelStyle(.iconOnly)
                .tint(.primary)
        }
    }
    
    @ViewBuilder
    private func mapButton<Content: View>(_ content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .font(.title2)
                .frame(width: 44, height: 44)
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .font(.title)
                .symbolVariant(.circle.fill)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    @ViewBuilder
    private func informationCard() -> some View {
        if !availableChartTypes.isEmpty {
            VStack(spacing: .regular) {
                VStack(spacing: .small) {
                    Picker("metric", selection: $selectedChartType) {
                        ForEach(availableChartTypes, id: \.self) { chartType in
                            Text(chartType.stringKey).tag(chartType)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    if let dateRange {
                        ChartZoomPicker(selection: $zoomLevel, duration: dateRange.lowerBound.distance(to: dateRange.upperBound))
                    }
                }
                chartContent
                    .frame(height: chartHeight)
            }
            .padding(.horizontal, .large)
            .padding(.vertical, padding)
            .background(content: MapOverlayBackground.init)
        }
    }
    
    @ViewBuilder private var chartContent: some View {
        if let dateRange {
            switch selectedChartType {
            case .speed:
                if let sectionedSpeeds {
                    SampleChart(
                        "speed",
                        unit: userPreferences.safeSpeedUnit(),
                        sectionedSamples: sectionedSpeeds,
                        dateRange: dateRange,
                        zoomLevel: zoomLevel,
                        selection: $selectedTimestamp
                    )
                }
            case .altitude:
                if let sectionedAltitudes {
                    SampleChart(
                        "altitude",
                        unit: userPreferences.safeAltitudeUnit(),
                        sectionedSamples: sectionedAltitudes,
                        dateRange: dateRange,
                        zoomLevel: zoomLevel,
                        selection: $selectedTimestamp
                    )
                }
            case .heartRate:
                if let sectionedHeartRates {
                    HeartRateChart(sectionedSamples: sectionedHeartRates, dateRange: dateRange, zoomLevel: zoomLevel, selection: $selectedTimestamp)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            mapStyleMenu
        }
    }
    
    @Sendable
    private func loadWorkout() async {
        do {
            let workoutId = id
            var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == workoutId })
            descriptor.fetchLimit = 1
            guard let workout = try modelContext.fetch(descriptor).first else { return }
            guard let endDate = workout.endDate, workout.startDate < endDate else { return }
            let startDate = workout.startDate
            let filteredSortedRoute = workout.route
                .filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
                .sorted(using: KeyPathComparator(\.timestamp))
            let filteredSortedHeartRates = workout.heartRates
                .filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
                .sorted(using: KeyPathComparator(\.timestamp))
            let sortedPauses = workout.pauses.sorted(using: KeyPathComparator(\.startDate))
            let routeSections = Calculation.calculateSectionedSamples(
                from: filteredSortedRoute,
                timestampKeyPath: \.timestamp,
                pauses: sortedPauses
            )
            let heartRateSections = Calculation.calculateSectionedSamples(
                from: filteredSortedHeartRates,
                timestampKeyPath: \.timestamp,
                pauses: sortedPauses
            )
            sortedRoute = filteredSortedRoute
            sectionedRoute = [(false, filteredSortedRoute)] + routeSections.filter { $0.category }
            sectionedHeartRates = heartRateSections
            dateRange = startDate...endDate
            sectionedAltitudes = Calculation.calculateSectionedValues(
                from: sectionedRoute,
                for: \.validatedAltitude,
                and: \.timestamp,
                sourceUnit: .meters,
                destinationUnit: userPreferences.safeAltitudeUnit()
            )
            sectionedSpeeds = Calculation.calculateSectionedValues(
                from: sectionedRoute,
                for: \.validatedSpeed,
                and: \.timestamp,
                sourceUnit: .metersPerSecond,
                destinationUnit: userPreferences.safeSpeedUnit()
            )
        } catch {
            self.error = error
        }
    }
    
    private struct RouteSection: Identifiable {
        let id: Int
        let active: Bool
        let coordinates: [CLLocationCoordinate2D]
    }
    
    private enum MapStyleSelection: String, CaseIterable, Identifiable, Hashable {
        case standard, hybrid, imagery
        
        var id: String { rawValue }
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .standard: "workout_map_style_standard"
            case .hybrid: "workout_map_style_hybrid"
            case .imagery: "workout_map_style_imagery"
            }
        }
        
        var systemImage: String {
            switch self {
            case .standard: "map"
            case .hybrid: "map.fill"
            case .imagery: "globe.europe.africa.fill"
            }
        }
        
        var style: MapStyle {
            switch self {
            case .standard: .standard(elevation: .automatic)
            case .hybrid: .hybrid(elevation: .flat)
            case .imagery: .imagery(elevation: .realistic)
            }
        }
    }
}
