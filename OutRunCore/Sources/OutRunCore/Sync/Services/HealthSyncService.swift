import CoreLocation
import Foundation
import HealthKit
import OSLog
import Perception

@MainActor
@Observable
public class HealthSyncService: SyncService {
    
    public static nonisolated let identifier = "HealthSyncService"
    
    private let logger = Logger(category: identifier)
    private let healthStore = HKHealthStore()
    private var delegate: SyncDelegate?
    
    public let identifier: String = identifier
    public private(set) var inwardSyncMode: SyncMode = .disabled
    public private(set) var outwardSyncMode: SyncMode = .disabled
    public let relevantAttributes: Set<any PartialKeyPath<Workout> & Sendable> = [
        \.rawType,
         \.distance,
         \.startDate,
         \.endDate,
         \.energy,
         \.repetitions,
         \.rawSource,
         \.route,
         \.heartRates,
         \.pauses,
         \.events,
    ]
    
    public func setInwardSyncMode(_ mode: SyncMode) {
        guard let delegate, inwardSyncMode != mode else { return }
        let now = Date.now
        switch (inwardSyncMode, mode) {
        case (_, .disabled):
            observationAnchor = nil
        case (.disabled, .enabledFrom(let startDate)):
            initiallySync(from: startDate, to: now, into: delegate)
        case (.disabled, .enabled):
            initiallySync(from: nil, to: now, into: delegate)
        default:
            break
        }
        inwardSyncMode = mode
        setPreference(inwardSyncMode, for: Self.inwardSyncModePreferenceKey)
    }
    
    public func setOutwardSyncMode(_ mode: SyncMode) {
        guard delegate != nil, outwardSyncMode != mode else { return }
        outwardSyncMode = mode
        setPreference(outwardSyncMode, for: Self.outwardSyncModePreferenceKey)
    }
    
    public init() {
        Task { [weak self] in
            let shouldObserveSequence = Perceptions { self?.delegate != nil && self?.inwardSyncMode.isEnabled == true }
                .buffer(policy: .unbounded)
                .removeDuplicates()
            for await shouldObserve in shouldObserveSequence {
                guard let self else { return }
                if shouldObserve {
                    startObservation()
                } else {
                    endObservation()
                }
            }
        }
    }
    
    // MARK: - Preferences
    
    private static let inwardSyncModePreferenceKey = "inwardSyncMode"
    private static let outwardSyncModePreferenceKey = "outwardSyncMode"
    private static let observationAnchorDataPreferenceKey = "observationAnchorData"
    
    private func preferenceKey(for key: String) -> String {
        identifier + "." + key
    }
    
    private func preference<T: Codable>(for key: String) -> T? {
        let preferenceKey = preferenceKey(for: key)
        guard let data = delegate?.devicePreference(for: preferenceKey) as? Data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    private func setPreference<T: Codable>(_ value: T?, for key: String) {
        let preferenceKey = preferenceKey(for: key)
        do {
            let data = try JSONEncoder().encode(value)
            delegate?.setDevicePreference(data, for: preferenceKey)
        } catch {
            logger.error("Failed to save \"\(key)\" preference value: \(error)")
        }
    }
    
    // MARK: - Health Kit
    
    // MARK: Authorization
    
    enum SupportedHealthKitType: CaseIterable {
        case workout
        case workoutRoute
        case sampleActiveEnergyBurned
        case sampleHeartRate
        case sampleDistanceWalkingRunning
        case sampleDistanceCycling
        case sampleDistanceSkatingSports
        case sampleStepCount
        
        fileprivate var sampleType: HKSampleType {
            switch self {
            case .workout:
                HKSampleType.workoutType()
            case .workoutRoute:
                HKSeriesType.workoutRoute()
            case .sampleActiveEnergyBurned:
                HKQuantityType(.activeEnergyBurned)
            case .sampleHeartRate:
                HKQuantityType(.heartRate)
            case .sampleDistanceWalkingRunning:
                HKQuantityType(.distanceWalkingRunning)
            case .sampleDistanceCycling:
                HKQuantityType(.distanceCycling)
            case .sampleDistanceSkatingSports:
                HKQuantityType(.distanceSkatingSports)
            case .sampleStepCount:
                HKQuantityType(.stepCount)
            }
        }
        
        fileprivate var quanityType: HKQuantityType? {
            sampleType as? HKQuantityType
        }
        
        fileprivate var quantityUnit: HKUnit? {
            switch self {
            case .sampleActiveEnergyBurned:
                .joule()
            case .sampleHeartRate:
                .count().unitDivided(by: .minute())
            case .sampleDistanceWalkingRunning, .sampleDistanceCycling, .sampleDistanceSkatingSports:
                .meter()
            case .sampleStepCount:
                .count()
            default:
                .none
            }
        }
        
        fileprivate var supportsCumulativeAggregation: Bool {
            switch self {
            case .sampleActiveEnergyBurned,
                 .sampleDistanceWalkingRunning,
                 .sampleDistanceCycling,
                 .sampleDistanceSkatingSports,
                 .sampleStepCount:
                true
            case .workout, .workoutRoute, .sampleHeartRate:
                false
            }
        }
    }
    
    /// Requests read and write authorization for the types supported by this sync service.
    public func requestAuthorization() async throws {
        let types = Set(SupportedHealthKitType.allCases.map(\.sampleType))
        let status = try await healthStore.statusForAuthorizationRequest(toShare: types, read: types)
        switch status {
        case .shouldRequest:
            try await healthStore.requestAuthorization(toShare: types, read: types)
        case .unnecessary:
            throw HealthSyncServiceError.permissionPromptUnavailable
        case .unknown:
            fallthrough
        @unknown default:
            throw HealthSyncServiceError.unknown
        }
    }
    
    private func checkMissingAuthorization() async throws {
        let types = Set(SupportedHealthKitType.allCases.map(\.sampleType))
        let status = try await healthStore.statusForAuthorizationRequest(toShare: types, read: types)
        switch status {
        case .shouldRequest:
            // The user should be prompted to provide authorization for types that are not determined.
            throw HealthSyncServiceError.authorizationMissing
        case .unnecessary:
            // As long as there is authorization to write the workout object, the permissions given by the user should be respected.
            guard await isAuthorizedToWrite(.workout) else { throw HealthSyncServiceError.authorizationDenied }
        case .unknown:
            fallthrough
        @unknown default:
            throw HealthSyncServiceError.unknown
        }
    }
    
    private func checkWriteAuthorization(for type: SupportedHealthKitType) async throws(HealthSyncServiceError) {
        switch healthStore.authorizationStatus(for: type.sampleType) {
        case .sharingAuthorized:
            return
        case .notDetermined:
            throw .authorizationMissing
        case .sharingDenied:
            throw .authorizationDenied
        @unknown default:
            throw .unknown
        }
    }
    
    private func isAuthorizedToWrite(_ type: SupportedHealthKitType) async -> Bool {
        do {
            try await checkWriteAuthorization(for: type)
        } catch {
            return false
        }
        return true
    }
    
    // MARK: - Inward Sync
    
    private func attemptToInwardSync(_ hkWorkout: HKWorkout, into delegate: any SyncDelegate) async {
        do {
            let workout = try await fetchFullWorkout(from: hkWorkout)
            try await delegate.upsert(workout)
            logger.info("Successfully upserted workout \(hkWorkout.uuid.uuidString) inward.")
        } catch {
            logger.error("Failed to upsert workout \(hkWorkout.uuid.uuidString) inward: \(error.localizedDescription)")
        }
    }
    
    private func initiallySync(from startDate: Date?, to endDate: Date?, into delegate: any SyncDelegate) {
        Task {
            do {
                logger.info("Attempting to initial inward sync from \(startDate ?? .distantPast) to \(endDate ?? .distantFuture).")
                let hkWorkouts = try await fetchWorkouts(from: startDate, to: endDate)
                for hkWorkout in hkWorkouts {
                    await attemptToInwardSync(hkWorkout, into: delegate)
                }
                logger.info("Finished initial inward sync from \(startDate ?? .distantPast) to \(endDate ?? .distantFuture).")
            } catch {
                logger.error("Initial inward sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Observation
    
    private var observationTask: Task<Void, Never>?
    private var observationAnchor: HKQueryAnchor? {
        get {
            guard let delegate,
                  let data = delegate.devicePreference(for: Self.observationAnchorDataPreferenceKey) as? Data,
                  let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
            else { return nil }
            return anchor
        } set {
            guard let delegate, let newValue, let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)
            else { return }
            delegate.setDevicePreference(data, for: Self.observationAnchorDataPreferenceKey)
        }
    }
    
    private func workoutPredicate(from startDate: Date?, to endDate: Date?) -> HKSamplePredicate<HKWorkout> {
        let sourcePredicate = HKQuery.predicateForObjects(from: .default())
        let syncStartDatePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let activityTypePredicates = WorkoutType.allCases.map { HKQuery.predicateForWorkouts(with: $0.healthKitType) }
        let activityTypesPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: activityTypePredicates)
        let filterPredicares = [syncStartDatePredicate, activityTypesPredicate]
        let filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: filterPredicares)
        return HKSamplePredicate.workout(filterPredicate)
    }
    
    private func startObservation() {
        guard inwardSyncMode.isEnabled else {
            logger.error("Tried to start observation in disabled mode.")
            return
        }
        let observationAnchor = self.observationAnchor
        let workoutPredicate = workoutPredicate(from: inwardSyncMode.startDate, to: .none)
        let descriptor = HKAnchoredObjectQueryDescriptor(predicates: [workoutPredicate], anchor: observationAnchor)
        observationTask = Task { [weak delegate] in
            do {
                for try await result in descriptor.results(for: healthStore) {
                    try Task.checkCancellation()
                    for hkWorkout in result.addedSamples {
                        try Task.checkCancellation()
                        guard let delegate else { throw CancellationError() }
                        do {
                            let workout = try await fetchFullWorkout(from: hkWorkout)
                            try await delegate.upsert(workout)
                            logger.info("Successfully upserted workout \(hkWorkout.uuid.uuidString) inward.")
                        } catch {
                            logger.error("Failed to upsert workout \(hkWorkout.uuid.uuidString) inward: \(error.localizedDescription)")
                        }
                    }
                    for deletedHKWorkout in result.deletedObjects {
                        try Task.checkCancellation()
                        guard let delegate else { throw CancellationError() }
                        let healthIdentifier = deletedHKWorkout.uuid.uuidString
                        do {
                            try await delegate.delete(workoutWithExternalIdentifier: healthIdentifier, forServiceWith: identifier)
                            logger.info("Successfully propagated workout delete for \(healthIdentifier) inward.")
                        } catch {
                            logger.error("Failed to propagate workout delete for \(healthIdentifier) inward: \(error.localizedDescription)")
                        }
                    }
                    self.observationAnchor = result.newAnchor
                }
            } catch is CancellationError {
                logger.error("Cancelled observation task.")
            } catch {
                logger.error("Observation Task failed: \(error.localizedDescription)")
            }
        }
        logger.info("Started observation.")
    }
    
    private func endObservation() {
        guard let observationTask else {
            logger.warning("Tried to cancel observation prior to starting one.")
            return
        }
        observationTask.cancel()
        self.observationTask = nil
        logger.info("Ended observation.")
    }
    
    // MARK: Query
    
    /// Queries the workout with the given id assigned as `HKMetadataKeyExternalUUID` metadata or optionally the HealthKit assigned id.
    /// - warning: This function will only work for workouts that were exported by your app and have the metadata key set or for which you
    /// provide a HealthKit assigned id.
    private func queryHKWorkout(with id: UUID, or healthID: String? = .none) async throws -> HKWorkout? {
        let sourcePredicate = HKQuery.predicateForObjects(from: .default())
        let uuidPredicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyExternalUUID, allowedValues: [id.uuidString])
        let idPredicate = if let healthUUIDPredicate = healthID.map(UUID.init(uuidString:))?.map(HKQuery.predicateForObject(with:)) {
            NSCompoundPredicate(orPredicateWithSubpredicates: [healthUUIDPredicate, uuidPredicate])
        } else {
            uuidPredicate
        }
        let workoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sourcePredicate, idPredicate])
        let workoutSamplePredicate = HKSamplePredicate.workout(workoutPredicate)
        let workoutSampleQueryDescriptor = HKSampleQueryDescriptor(predicates: [workoutSamplePredicate], sortDescriptors: [], limit: 1)
        return try await workoutSampleQueryDescriptor.result(for: healthStore).first
    }
    
    private func fetchCumulativeMetric(for hkWorkout: HKWorkout, with type: SupportedHealthKitType?) async throws -> Double? {
        guard let type else { return nil }
        guard type.supportsCumulativeAggregation,
              let quantityType = type.quanityType,
              let quantityUnit = type.quantityUnit
        else { throw HealthSyncServiceError.invalidHealthKitType }
        let workoutAssociatedPredicate = HKQuery.predicateForObjects(from: hkWorkout)
        let typePredicate = HKSamplePredicate.quantitySample(type: quantityType, predicate: workoutAssociatedPredicate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: typePredicate, options: .cumulativeSum)
        let result = try await descriptor.result(for: healthStore)
        return result?.sumQuantity()?.doubleValue(for: quantityUnit)
    }
    
    private func fetchHeartRates(for hkWorkout: HKWorkout) async throws -> [RawWorkoutHeartRateDataSample] {
        let type = SupportedHealthKitType.sampleHeartRate
        guard let quantityType = type.quanityType, let quantityUnit = type.quantityUnit else { throw HealthSyncServiceError.unknown }
        let workoutAssociatedPredicate = HKQuery.predicateForObjects(from: hkWorkout)
        let heartRatePredicate = HKSamplePredicate.quantitySample(type: quantityType, predicate: workoutAssociatedPredicate)
        let descriptor = HKQuantitySeriesSampleQueryDescriptor(predicate: heartRatePredicate, options: .orderByQuantitySampleStartDate)
        let heartRateSampleSequence = descriptor.results(for: healthStore)
        var heartRates: [RawWorkoutHeartRateDataSample] = []
        for try await heartRateSample in heartRateSampleSequence {
            let heartRate = UInt8(heartRateSample.quantity.doubleValue(for: quantityUnit))
            let startDate = heartRateSample.dateInterval.start
            heartRates.append(.init(heartRate: heartRate, timestamp: startDate))
            let endDate = heartRateSample.dateInterval.end
            guard startDate != endDate else { continue }
            heartRates.append(.init(heartRate: heartRate, timestamp: endDate))
        }
        return heartRates
    }
    
    private func fetchRoute(for hkWorkout: HKWorkout) async throws -> [RawWorkoutRouteDataSample] {
        let workoutAssociatedPredicate = HKQuery.predicateForObjects(from: hkWorkout)
        let routePredicate = HKSamplePredicate.workoutRoute(workoutAssociatedPredicate)
        let routesDescriptor = HKSampleQueryDescriptor(predicates: [routePredicate], sortDescriptors: [])
        let routes = try await routesDescriptor.result(for: healthStore)
        var routeSamples: [RawWorkoutRouteDataSample] = []
        for route in routes {
            let locationsDescriptor = HKWorkoutRouteQueryDescriptor(route)
            let locationSequence = locationsDescriptor.results(for: healthStore)
            for try await location in locationSequence {
                routeSamples.append(.init(from: location))
            }
        }
        return routeSamples
    }
    
    private func fetchFullWorkout(from hkWorkout: HKWorkout) async throws -> RawWorkout {
        guard let workoutType = WorkoutType(hkType: hkWorkout.workoutActivityType)
        else { throw HealthSyncServiceError.unsupportedActivityType }
        let now = Date.now
        let startDate = hkWorkout.startDate
        let endDate = hkWorkout.endDate
        let pauseEvents = hkWorkout.workoutEvents?.compactMap { event -> Calculation.PauseEvent? in
            let timestamp = event.dateInterval.start
            return switch event.type {
            case .pause: .init(date: timestamp, type: .pause)
            case .resume: .init(date: timestamp, type: .resume)
            default: nil
            }
        }
        let pauses = pauseEvents.map { Calculation.calculatePauses(from: $0, workoutStart: startDate, workoutEnd: endDate) }
        let events = hkWorkout.workoutEvents?.compactMap { event -> RawWorkoutEvent? in
            guard let type = WorkoutEventType(healthType: event.type) else { return nil }
            return .init(type: type, timestamp: event.dateInterval.start)
        }
        return .init(
            id: .init(),
            type: workoutType,
            distance: try await fetchCumulativeMetric(for: hkWorkout, with: workoutType.healthKitDistanceType) ?? .zero,
            startDate: startDate,
            endDate: endDate,
            energy: try await fetchCumulativeMetric(for: hkWorkout, with: .sampleActiveEnergyBurned),
            repetitions: try await fetchCumulativeMetric(for: hkWorkout, with: workoutType.healthKitRepetitionsType).map(Int.init),
            isRace: false,
            name: hkWorkout.metadata?[HKMetadataKeyWorkoutBrandName] as? String,
            comment: .none,
            creationDate: startDate,
            lastEditDate: startDate,
            source: hkWorkout.sourceRevision.source == .default() ? .native : .syncService(identifier: identifier),
            heartRates: try await fetchHeartRates(for: hkWorkout),
            route: try await fetchRoute(for: hkWorkout),
            pauses: pauses ?? [],
            events: events ?? [],
            serviceMappings: [
                .init(
                    serviceIdentifier: identifier,
                    externalId: hkWorkout.uuid.uuidString,
                    externalUrl: .none,
                    lastEditDateSynced: now,
                    syncStatus: .synced
                )
            ]
        )
    }
    
    private func fetchWorkouts(from startDate: Date?, to endDate: Date?) async throws -> [HKWorkout] {
        let workoutPredicate = workoutPredicate(from: startDate, to: endDate)
        let descriptor = HKSampleQueryDescriptor(predicates: [workoutPredicate], sortDescriptors: [])
        return try await descriptor.result(for: healthStore)
    }
    
    // MARK: Insert
    
    private func config(for activityType: HKWorkoutActivityType) -> HKWorkoutConfiguration {
        let config = HKWorkoutConfiguration()
        config.activityType = activityType
        return config
    }
    
    private func initializeWorkoutBuilder(for config: HKWorkoutConfiguration) -> HKWorkoutBuilder {
        .init(healthStore: healthStore, configuration: config, device: .none)
    }
    
    private func initializeRouteBuilder(for workout: RawWorkout, from workoutBuilder: HKWorkoutBuilder) async -> HKWorkoutRouteBuilder? {
        guard !workout.route.isEmpty, await isAuthorizedToWrite(.workoutRoute) else { return nil }
        return workoutBuilder.seriesBuilder(for: .workoutRoute()) as? HKWorkoutRouteBuilder
    }
    
    private func addMetadata(for workout: RawWorkout, to workoutBuilder: HKWorkoutBuilder) async throws {
        let uuidString = workout.id.uuidString
        let version = NSNumber(integerLiteral: workout.lastEditDate.unixTimestamp)
        let metadata: [String: Any] = [
            HKMetadataKeyExternalUUID: uuidString,
            HKMetadataKeySyncIdentifier: uuidString,
            HKMetadataKeySyncVersion: version
        ]
        try await workoutBuilder.addMetadata(metadata)
    }
    
    private func createQuantitySample(
        ofType type: SupportedHealthKitType?,
        value: Double?,
        for workout: RawWorkout,
        addTo collection: inout [HKQuantitySample]
    ) async {
        guard let endDate = workout.endDate,
              let type,
              let quanityType = type.quanityType,
              let quantityUnit = type.quantityUnit,
              let value,
              await isAuthorizedToWrite(type)
        else { return }
        let quantity = HKQuantity(unit: quantityUnit, doubleValue: value)
        let sample = HKQuantitySample(type: quanityType, quantity: quantity, start: workout.startDate, end: endDate, metadata: .none)
        collection.append(sample)
    }
    
    private func addQuanitySamples(for workout: RawWorkout, to workoutBuilder: HKWorkoutBuilder) async throws {
        let distance = workout.distance
        let energy = workout.energy
        let repetitions = workout.repetitions.map(Double.init)
        var quantitySamples: [HKQuantitySample] = []
        await createQuantitySample(ofType: workout.type.healthKitDistanceType, value: distance, for: workout, addTo: &quantitySamples)
        await createQuantitySample(ofType: .sampleActiveEnergyBurned, value: energy, for: workout, addTo: &quantitySamples)
        await createQuantitySample(ofType: workout.type.healthKitRepetitionsType, value: repetitions, for: workout, addTo: &quantitySamples)
        try await workoutBuilder.addSamples(quantitySamples)
    }
    
    private func addWorkoutEvents(for workout: RawWorkout, to workoutBuilder: HKWorkoutBuilder) async throws {
        let workoutEvents = workout.events.compactMap { event -> HKWorkoutEvent? in
            event.type.healthKitType.map { .init(type: $0, dateInterval: .init(start: event.timestamp, duration: .zero), metadata: .none) }
        }
        let workoutPauseEvents = workout.pauses.flatMap {[
            HKWorkoutEvent(type: .pause, dateInterval: .init(start: $0.startDate, duration: .zero), metadata: .none),
            HKWorkoutEvent(type: .resume, dateInterval: .init(start: $0.endDate, duration: .zero), metadata: .none)
        ]}
        guard !workoutEvents.isEmpty || !workoutPauseEvents.isEmpty else { return }
        try await workoutBuilder.addWorkoutEvents(workoutEvents + workoutPauseEvents)
    }
    
    private func addHeartRates(for workout: RawWorkout, to workoutBuilder: HKWorkoutBuilder) async throws {
        guard !workout.heartRates.isEmpty, await isAuthorizedToWrite(.sampleHeartRate) else { return }
        let heartRateSampleBuilder = HKQuantitySeriesSampleBuilder(
            healthStore: healthStore,
            quantityType: .init(.heartRate),
            startDate: workout.startDate,
            device: .none
        )
        for sample in workout.heartRates {
            let heartRateQuantity = HKQuantity(unit: .count().unitDivided(by: .minute()), doubleValue: Double(sample.heartRate))
            try heartRateSampleBuilder.insert(heartRateQuantity, at: sample.timestamp)
        }
        let heartRateSamples = try await heartRateSampleBuilder.finishSeries(metadata: nil, endDate: workout.endDate)
        try await workoutBuilder.addSamples(heartRateSamples)
    }
    
    private func addRouteData(for workout: RawWorkout, to routeBuilder: HKWorkoutRouteBuilder?) async throws {
        guard let routeBuilder, !workout.route.isEmpty else { return }
        let locations = workout.route.map(CLLocation.init)
        try await routeBuilder.insertRouteData(locations)
    }
    
    /// Inserts the workout and associated objects into HealthKit.
    private func insertHKWorkout(from workout: RawWorkout) async throws -> HKWorkout {
        guard let endDate = workout.endDate else { throw SyncError.unknown }
        let config = config(for: workout.type.healthKitType)
        let workoutBuilder = initializeWorkoutBuilder(for: config)
        let routeBuilder = await initializeRouteBuilder(for: workout, from: workoutBuilder)
        try await workoutBuilder.beginCollection(at: workout.startDate)
        try await addMetadata(for: workout, to: workoutBuilder)
        try await addWorkoutEvents(for: workout, to: workoutBuilder)
        try await addQuanitySamples(for: workout, to: workoutBuilder)
        try await addHeartRates(for: workout, to: workoutBuilder)
        try await addRouteData(for: workout, to: routeBuilder)
        try await workoutBuilder.endCollection(at: endDate)
        guard let hkWorkout = try await workoutBuilder.finishWorkout() else { throw SyncError.unknown }
        // Against what the documentation says, the routeBuilder should not explicitly be finished through .finishRoute(with:metadata:) as
        // this raises the error: com.apple.healthkit Code=3 "This route builder is attached to a workout builder and will be finished with
        // the workout builder"
        return hkWorkout
    }
    
    // MARK: Delete
    
    /// Deletes the given HealthKit workout and the associated objects.
    private func deleteHKWorkout(_ hkWorkout: HKWorkout) async throws {
        let associatedObjectPredicate = HKQuery.predicateForObjects(from: hkWorkout)
        for type in SupportedHealthKitType.allCases where type != .workout {
            try await healthStore.deleteObjects(of: type.sampleType, predicate: associatedObjectPredicate)
        }
        try await healthStore.delete(hkWorkout)
    }
    
    /// Deletes the workout with the given id assigned as `HKMetadataKeyExternalUUID` metadata and the associated objects.
    private func deleteHKWorkout(with id: UUID, or healthID: String? = .none) async throws {
        guard let hkWorkout = try await queryHKWorkout(with: id, or: healthID) else { throw HealthSyncServiceError.objectNotFound }
        try await deleteHKWorkout(hkWorkout)
    }
    
    // MARK: - SyncService
    
    public func initialize(with delegate: any SyncDelegate) async {
        self.delegate = delegate
        inwardSyncMode = preference(for: Self.inwardSyncModePreferenceKey) ?? .disabled
        outwardSyncMode = preference(for: Self.outwardSyncModePreferenceKey) ?? .disabled
        logger.info("Initialized.")
    }
    
    public func deinitialize() async {
        delegate = nil
        inwardSyncMode = .disabled
        outwardSyncMode = .disabled
        logger.info("Deinitialized.")
    }
    
    public func upsert(_ workout: RawWorkout) async throws -> (id: String?, url: String?) {
        do {
            try await checkMissingAuthorization()
            let healthID = workout.serviceMappings.first(where: { $0.serviceIdentifier == identifier })?.externalId
            if let hkWorkout = try await queryHKWorkout(with: workout.id, or: healthID) {
                if let version = (hkWorkout.metadata?[HKMetadataKeySyncVersion] as? NSNumber)?.intValue {
                    let upsertVersion = workout.lastEditDate.unixTimestamp
                    if version == upsertVersion {
                        logger.warning("Attempted to upsert workout \(workout.id) again.")
                        return (hkWorkout.uuid.uuidString, nil)
                    } else if version > upsertVersion {
                        // A newer version of the workout is already synced to the service. The conflict should be resolved manually.
                        throw SyncError.conflict
                    }
                }
                try await deleteHKWorkout(hkWorkout)
                logger.info("Deleted workout \(workout.id) prior to insertion to avoid duplication.")
            }
            let hkWorkout = try await insertHKWorkout(from: workout)
            logger.debug("Successfully inserted workout \(workout.id).")
            return (hkWorkout.uuid.uuidString, nil)
        } catch HealthSyncServiceError.authorizationMissing {
            logger.error("The user has not granted access to HealthKit.")
            throw SyncError.authenticationRequired
        } catch {
            logger.error("Failed to insert workout \(workout.id): \(error)")
            throw error
        }
    }
    
    public func delete(workoutWith identifier: UUID) async throws {
        do {
            try await deleteHKWorkout(with: identifier)
            logger.info("Successfully deleted workout \(identifier).")
        } catch HealthSyncServiceError.objectNotFound {
            logger.warning("Attempted delete of non-existent workout \(identifier).")
        } catch {
            logger.error("Failed to delete workout \(identifier).")
            throw error
        }
    }
}
