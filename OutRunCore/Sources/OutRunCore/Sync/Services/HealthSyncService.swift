import CoreLocation
import Foundation
import HealthKit
import OSLog
import SwiftUI

@MainActor
@Observable
public class HealthSyncService: SyncService {
    
    public static nonisolated let identifier = "HealthSyncService"
    
    private let logger = Logger(category: identifier)
    private let healthStore = HKHealthStore()
    private var delegate: SyncDelegate?
    
    public let identifier: String = identifier
    public private(set) var mode: SyncMode = .disabled {
        didSet {
            setPreference(mode, for: "syncMode")
        }
    }
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
    
    public init() {}
    
    // MARK: DEBUG
    
    public func setMode(_ mode: SyncMode) {
        self.mode = mode
    }
    
    // MARK: - Preferences
    
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
    
    // MARK: Query
    
    /// Queries the workout with the given id assigned as `HKMetadataKeyExternalUUID` metadata.
    /// - warning: This function will only work for workouts that were exported by your app and have the metadata key set.
    private func queryHKWorkout(with id: UUID) async throws -> HKWorkout? {
        let sourcePredicate = HKQuery.predicateForObjects(from: .default())
        let uuidPredicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeyExternalUUID, allowedValues: [id.uuidString])
        let workoutPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sourcePredicate, uuidPredicate])
        let workoutSamplePredicate = HKSamplePredicate.workout(workoutPredicate)
        let workoutSampleQueryDescriptor = HKSampleQueryDescriptor(predicates: [workoutSamplePredicate], sortDescriptors: [], limit: 1)
        return try await workoutSampleQueryDescriptor.result(for: healthStore).first
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
        unit: HKUnit,
        for workout: RawWorkout,
        addTo collection: inout [HKQuantitySample]
    ) async {
        guard let endDate = workout.endDate, let type, let quanityType = type.quanityType, let value, await isAuthorizedToWrite(type)
        else { return }
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(type: quanityType, quantity: quantity, start: workout.startDate, end: endDate, metadata: .none)
        collection.append(sample)
    }
    
    private func addQuanitySamples(for workout: RawWorkout, to workoutBuilder: HKWorkoutBuilder) async throws {
        var quantitySamples: [HKQuantitySample] = []
        await createQuantitySample(
            ofType: workout.type.healthKitDistanceType,
            value: workout.distance,
            unit: .meter(),
            for: workout,
            addTo: &quantitySamples
        )
        await createQuantitySample(
            ofType: .sampleActiveEnergyBurned,
            value: workout.energy,
            unit: .joule(),
            for: workout,
            addTo: &quantitySamples
        )
        await createQuantitySample(
            ofType: workout.type.healthKitRepetitionsType,
            value: workout.repetitions.map(Double.init),
            unit: .count(),
            for: workout,
            addTo: &quantitySamples
        )
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
    private func deleteHKWorkout(with id: UUID) async throws {
        guard let hkWorkout = try await queryHKWorkout(with: id) else { throw HealthSyncServiceError.objectNotFound }
        try await deleteHKWorkout(hkWorkout)
    }
    
    // MARK: - SyncService
    
    public func initialize(with delegate: any SyncDelegate) async {
        self.delegate = delegate
        self.mode = preference(for: "syncMode") ?? .disabled
    }
    
    public func deinitialize() async {
        delegate = nil
    }
    
    public func upsert(_ workout: RawWorkout) async throws -> (id: String?, url: String?) {
        do {
            try await checkMissingAuthorization()
            if let hkWorkout = try await queryHKWorkout(with: workout.id) {
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
