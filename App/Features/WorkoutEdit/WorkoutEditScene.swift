import Charts
import CoreLocation
import OutRunCore
import SwiftData
import SwiftUI

struct WorkoutEditScene: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @Environment(\.modelContext) private var modelContext
    @Environment(OutRunCore.self) private var core
    @Environment(UserPreferences.self) private var userPreferences
    @Query private var lastWorkout: [Workout]
    
    @State private var selectedChartType: ChartType = .speed
    @State private var expandedPauseIds: Set<UUID> = []
    @State private var confirmRouteTruncation: Bool = false
    @State private var error: Error?
    @State private var sectionedRoute: CategorizedArray<Bool, any WorkoutRouteDataSampleProtocol>?
    @State private var sectionedHeartRates: CategorizedArray<Bool, any WorkoutHeartRateDataSampleProtocol>?
    
    @State private var name: String
    @State private var type: WorkoutType?
    @State private var isRace: Bool
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var distance: Double?
    @State private var energy: Double?
    @State private var repetitions: Int?
    @State private var editablePauses: [EditablePause]
    @State private var comment: String
    
    private let workout: (any WorkoutProtocol)?
    private let sortedRoute: [any WorkoutRouteDataSampleProtocol]
    private let addCloseButton: Bool
    private let originalPauses: [EditablePause]
    private let chartHeight: CGFloat = 150
    
    private var defaultWorkoutType: WorkoutType { userPreferences.defaultWorkoutType ?? lastWorkout.last?.type ?? .running }
    private var disableSaveButton: Bool {
        guard type != nil, startDate < endDate, distance != nil else { return true }
        return false
    }
    
    private var calculatedEnergy: Double? {
        guard let distance, let type else { return nil }
        return Calculation.calculateBurnedEnergy(weight: core.user?.weight, distance: distance, workoutType: type)
    }

    private var distanceMeasurement: Binding<Measurement<UnitLength>?> {
        .init {
            guard let distance else { return nil }
            return .init(value: distance, unit: .meters)
        } set: { measurement in
            distance = measurement?.converted(to: .meters).value
        }
    }
    
    private var energyMeasurement: Binding<Measurement<UnitEnergy>?> {
        .init {
            guard let energy else { return nil }
            return .init(value: energy, unit: .joules)
        } set: { measurement in
            energy = measurement?.converted(to: .joules).value
        }
    }

    private var title: LocalizedStringKey {
        if workout == nil {
            "create_workout"
        } else {
            "edit_workout"
        }
    }
    
    private var optionalName: String? {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return name
    }
    private var optionalComment: String? {
        guard !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return comment
    }

    private var conflictingPauseIds: Set<UUID> {
        var conflicts = Set<UUID>()
        for i in editablePauses.indices {
            let a = editablePauses[i]
            if a.startDate >= a.endDate || a.startDate < startDate || a.endDate > endDate {
                conflicts.insert(a.id)
            }
            for j in (i + 1)..<editablePauses.count {
                let b = editablePauses[j]
                if a.startDate < b.endDate && b.startDate < a.endDate {
                    conflicts.insert(a.id)
                    conflicts.insert(b.id)
                }
            }
        }
        return conflicts
    }

    private var sortedValidPauses: [EditablePause] {
        editablePauses
            .filter { !conflictingPauseIds.contains($0.id) }
            .sorted { $0.startDate < $1.startDate }
    }

    private var pausesChanged: Bool {
        guard editablePauses.count == originalPauses.count else { return true }
        let sortedCurrent = editablePauses.sorted { $0.startDate < $1.startDate }
        let sortedOriginal = originalPauses.sorted { $0.startDate < $1.startDate }
        return zip(sortedCurrent, sortedOriginal).contains {
            $0.startDate != $1.startDate || $0.endDate != $1.endDate || $0.userInitiated != $1.userInitiated
        }
    }

    private var sectionedAltitudes: Calculation.SectionedValues<Float>? {
        Calculation.calculateSectionedValues(
            from: sectionedRoute,
            for: \.validatedAltitude,
            and: \.timestamp,
            sourceUnit: .meters,
            destinationUnit: userPreferences.safeAltitudeUnit()
        )
    }
    
    private var sectionedSpeeds: Calculation.SectionedValues<Float>? {
        Calculation.calculateSectionedValues(
            from: sectionedRoute,
            for: \.validatedSpeed,
            and: \.timestamp,
            sourceUnit: .metersPerSecond,
            destinationUnit: userPreferences.safeSpeedUnit()
        )
    }

    private var availableChartTypes: [ChartType] {
        guard startDate < endDate else { return [] }
        var available: [ChartType] = []
        if sectionedSpeeds != nil { available.append(.speed) }
        if sectionedAltitudes != nil { available.append(.altitude) }
        if let hr = sectionedHeartRates, !hr.flatMap(\.elements).isEmpty { available.append(.heartRate) }
        return available
    }
    
    private var editablePausesBinding: Binding<[EditablePause]> {
        .init {
            editablePauses
        } set: { newEditablePauses in
            editablePauses = newEditablePauses.sorted(using: KeyPathComparator(\.startDate))
        }
    }
    
    private func isPauseExpandedBinding(for id: UUID) -> Binding<Bool> {
        .init {
            expandedPauseIds.contains(id)
        } set: { expanded in
            if expanded { expandedPauseIds.insert(id) } else { expandedPauseIds.remove(id) }
        }
    }

    var body: some View {
        Form {
            metadataSection
            metricsSection
            pausesSection
            commentSection
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: toolbarContent)
        .scrollDismissesKeyboard(.interactively)
        .errorAlert($error)
        .onAppear {
            guard type == nil else { return }
            type = defaultWorkoutType
        }
        .task(updateSectionedData)
        .onChange(of: editablePauses) { updateSectionedData() }
        .onChange(of: availableChartTypes) { _, newTypes in
            if !newTypes.isEmpty && !newTypes.contains(selectedChartType) {
                selectedChartType = newTypes[0]
            }
        }
        
    }

    @ViewBuilder private var metadataSection: some View {
        Section {
            LabeledContent("name") {
                TextField("optional", text: $name).multilineTextAlignment(.trailing)
            }
            Picker(WorkoutMetric.type.description, selection: $type) {
                ForEach(WorkoutType.allCases, id: \.hashValue) { type in
                    Text(verbatim: type.description).tag(type)
                }
            }
            Toggle("workout_is_race", isOn: $isRace)
        }
    }

    @ViewBuilder private var metricsSection: some View {
        Section {
            datePicker(WorkoutMetric.startTime.description, date: $startDate)
            datePicker(WorkoutMetric.endTime.description, date: $endDate)
            Group {
                LabeledContent(WorkoutMetric.distance.description) {
                    MeasurementTextField(
                        "required",
                        measurement: distanceMeasurement,
                        unit: userPreferences.safeDistanceUnit(for: locale),
                        fractionLength: 0...3
                    )
                }
                LabeledContent(WorkoutMetric.energy.description) {
                    MeasurementTextField(
                        "optional",
                        measurement: energyMeasurement,
                        unit: userPreferences.safeEnergyUnit(for: locale),
                        fractionLength: 0...0
                    )
                }
                LabeledContent(WorkoutMetric.repetitions.description(for: type ?? .running)) {
                    TextField("optional", value: $repetitions, format: .number.precision(.fractionLength(0)))
                }
            }
            .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder private var pausesSection: some View {
        if startDate < endDate, !availableChartTypes.isEmpty {
            Section("workout_edit_pauses") {
                Picker("metric", selection: $selectedChartType) {
                    ForEach(availableChartTypes, id: \.self) { chartType in
                        Text(chartType.stringKey).tag(chartType)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Group {
                    switch selectedChartType {
                    case .altitude:
                        if let sectionedAltitudes {
                            SampleChart("altitude", sectionedSamples: sectionedAltitudes, dateRange: startDate...endDate, pauses: sortedValidPauses)
                        }
                    case .speed:
                        if let sectionedSpeeds {
                            SampleChart("speed", sectionedSamples: sectionedSpeeds, dateRange: startDate...endDate, pauses: sortedValidPauses)
                        }
                    case .heartRate:
                        if let sectionedHeartRates {
                            HeartRateChart(sectionedSamples: sectionedHeartRates, dateRange: startDate...endDate)
                        }
                    }
                }
                .frame(height: chartHeight)
                ForEach(editablePausesBinding) { $pause in
                    pauseRow(for: $pause, workoutStart: startDate, workoutEnd: endDate)
                }
                Button("workout_edit_add_pause", systemImage: "plus", action: addPause)
                if let workout, !sortedRoute.isEmpty, pausesChanged || workout.distance != distance {
                    Button("workout_edit_recalculate_distance", systemImage: "arrow.clockwise", action: recalculateDistance)
                }
                if let workout, !sortedRoute.isEmpty, pausesChanged || workout.energy != energy || calculatedEnergy != energy {
                    Button("workout_edit_recalculate_energy", systemImage: "arrow.clockwise", action: recalculateEnergy)
                }
            }
        }
    }

    @ViewBuilder
    private func pauseRow(for pause: Binding<EditablePause>, workoutStart: Date, workoutEnd: Date) -> some View {
        let id = pause.wrappedValue.id
        let isConflicting = conflictingPauseIds.contains(id)
        let index = (editablePauses.firstIndex(where: { $0.id == id }) ?? 0) + 1
        DisclosureGroup(isExpanded: isPauseExpandedBinding(for: id)) {
            dateOffsetPicker("pause_start", selection: pause.startDate, startDate: workoutStart, endDate: workoutEnd)
            dateOffsetPicker("pause_end", selection: pause.endDate, startDate: workoutStart, endDate: workoutEnd)
        } label: {
            Label {
                Text("workout_edit_pause_title_\(index)")
            } icon: {
                Image(systemName: isConflicting ? "exclamationmark.triangle.fill" : "pause.circle")
                    .foregroundStyle(isConflicting ? AnyShapeStyle(Color.red) : AnyShapeStyle(.tint))
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("delete", role: .destructive) {
                    editablePauses.removeAll(where: { $0.id == id })
                }
            }
        }
    }
    
    @ViewBuilder private var commentSection: some View {
        Section("comment") {
            TextEditor(text: $comment)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 100)
        }
    }

    @ViewBuilder
    private func datePicker(_ title: String, date: Binding<Date>) -> some View {
        LabeledContent(title) {
            ExactDatePicker(selection: date, in: ...Date.now)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func dateOffsetPicker(_ titleKey: LocalizedStringKey, selection: Binding<Date>, startDate: Date, endDate: Date) -> some View {
        LabeledContent(titleKey) {
            DateOffsetPicker(selection: selection, startDate: startDate, endDate: endDate)
        }
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if addCloseButton {
            ToolbarItem(placement: .topBarLeading) {
                Button("close", systemImage: "xmark", action: dismiss.callAsFunction)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Group {
                let role: ButtonRole? = if #available(iOS 26.0, *) { .confirm } else { nil }
                Button(role: role, action: confirmOrSave) {
                    Text("save")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                }
            }
            .disabled(disableSaveButton)
            .confirmationDialog("workout_edit_route_truncation_confirmation_title", isPresented: $confirmRouteTruncation, titleVisibility: .visible) {
                Button("workout_edit_route_truncation_confirmation_action_truncate", role: .destructive) { save() }
                Button("workout_edit_route_truncation_confirmation_action_keep") { save(truncateRoute: false) }
            } message: {
                Text("workout_edit_route_truncation_confirmation_message")
            }
        }
    }

    init(workout: (any WorkoutProtocol)?, addCloseButton: Bool = true) {
        self.workout = workout
        self.addCloseButton = addCloseButton
        var lastWorkoutDescriptor = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        lastWorkoutDescriptor.fetchLimit = 1
        lastWorkoutDescriptor.propertiesToFetch = [\.rawType]
        _lastWorkout = Query(lastWorkoutDescriptor)

        name = workout?.name ?? ""
        type = workout?.type
        startDate = workout?.startDate ?? .now.addingTimeInterval(-15 * 60)
        endDate = workout?.endDate ?? .now
        distance = workout?.distance
        energy = workout?.energy
        repetitions = workout?.repetitions
        isRace = workout?.isRace ?? false
        let pauses = (workout?.pauses ?? []).sorted(using: KeyPathComparator(\.startDate)).map {
            EditablePause(startDate: $0.startDate, endDate: $0.endDate, userInitiated: $0.userInitiated)
        }
        editablePauses = pauses
        originalPauses = pauses
        comment = workout?.comment ?? ""
        sortedRoute = workout?.route.sorted(using: KeyPathComparator(\.timestamp)) ?? []
    }

    private func addPause() {
        guard startDate < endDate else { return }
        let start = startDate
        let end = start.addingTimeInterval(60)
        let pause = EditablePause(startDate: start, endDate: end, userInitiated: true)
        editablePausesBinding.wrappedValue.append(pause)
        expandedPauseIds.insert(pause.id)
    }

    private func recalculateDistance() {
        guard !sortedRoute.isEmpty, startDate < endDate else { return }
        let filteredRoute = sortedRoute.filter { $0.timestamp >= startDate && $0.timestamp < endDate }
        distance = Calculation.calculateDistance(from: filteredRoute, and: sortedValidPauses)
    }
    
    private func recalculateEnergy() {
        energy = calculatedEnergy
    }

    private func updateSectionedData() {
        guard let workout else { return }
        let validPauses: [any WorkoutPauseProtocol] = sortedValidPauses
        if !sortedRoute.isEmpty {
            sectionedRoute = Calculation.calculateSectionedSamples(
                from: sortedRoute,
                timestampKeyPath: \.timestamp,
                pauses: validPauses
            )
        }
        let sortedHeartRates = workout.heartRates.sorted(using: KeyPathComparator(\.timestamp))
        if !sortedHeartRates.isEmpty {
            sectionedHeartRates = Calculation.calculateSectionedSamples(
                from: sortedHeartRates,
                timestampKeyPath: \.timestamp,
                pauses: validPauses
            )
        }
    }
    
    private func confirmOrSave() {
        guard startDate < endDate,
              let firstTimestamp = sortedRoute.first?.timestamp,
              let lastTimestamp = sortedRoute.last?.timestamp,
              firstTimestamp < startDate || lastTimestamp >= endDate
        else { save(); return }
        confirmRouteTruncation = true
    }

    private func save(truncateRoute: Bool = true) {
        guard let type, startDate < endDate, let distance else { return }
        let name = optionalName
        let comment = optionalComment
        do {
            let tempWorkout: Workout
            if let workout = workout as? Workout {
                tempWorkout = workout
                tempWorkout.name = name
                tempWorkout.type = type
                tempWorkout.isRace = isRace
                tempWorkout.startDate = startDate
                tempWorkout.endDate = endDate
                tempWorkout.distance = distance
                tempWorkout.energy = energy
                tempWorkout.repetitions = repetitions
                tempWorkout.comment = comment
                tempWorkout.lastEditDate = .now
            } else if let workout {
                let id = workout.id
                var descriptor = FetchDescriptor<Workout>(predicate: #Predicate { $0.id == id })
                descriptor.fetchLimit = 1
                if let existingWorkout = try modelContext.fetch(descriptor).first {
                    tempWorkout = existingWorkout
                    tempWorkout.name = name
                    tempWorkout.type = type
                    tempWorkout.isRace = isRace
                    tempWorkout.startDate = startDate
                    tempWorkout.endDate = endDate
                    tempWorkout.distance = distance
                    tempWorkout.energy = energy
                    tempWorkout.repetitions = repetitions
                    tempWorkout.comment = comment
                    tempWorkout.lastEditDate = .now
                } else {
                    tempWorkout = Workout(from: workout)
                    tempWorkout.route = workout.route.map { WorkoutRouteDataSample(from: $0) }
                    tempWorkout.heartRates = workout.heartRates.map { WorkoutHeartRateDataSample(from: $0) }
                    tempWorkout.serviceMappings = workout.serviceMappings.map { SyncServiceMapping(from: $0) }
                    tempWorkout.events = workout.events.map { WorkoutEvent(from: $0) }
                    modelContext.insert(tempWorkout)
                }
            } else {
                tempWorkout = Workout(
                    type: type,
                    distance: distance,
                    startDate: startDate,
                    endDate: endDate,
                    energy: energy,
                    repetitions: repetitions,
                    isRace: isRace,
                    name: name,
                    comment: comment,
                    creationDate: .now,
                    source: .manuallyEntered
                )
                modelContext.insert(tempWorkout)
            }
            tempWorkout.pauses = editablePauses.map { WorkoutPause(from: $0) }
            if truncateRoute {
                for sample in tempWorkout.route where sample.timestamp < startDate || sample.timestamp >= endDate {
                    modelContext.delete(sample)
                }
            }
            try modelContext.save()
            dismiss()
        } catch {
            self.error = error
        }
    }

    private struct EditablePause: Identifiable, WorkoutPauseProtocol {
        var id = UUID()
        var startDate: Date
        var endDate: Date
        var userInitiated: Bool
        var duration: TimeInterval { startDate.distance(to: endDate) }
    }

    private enum ChartType: CaseIterable, Hashable {
        
        case speed, altitude, heartRate

        var stringKey: LocalizedStringKey {
            switch self {
            case .altitude: "altitude"
            case .speed: "speed"
            case .heartRate: "heart_rate"
            }
        }
    }
}
