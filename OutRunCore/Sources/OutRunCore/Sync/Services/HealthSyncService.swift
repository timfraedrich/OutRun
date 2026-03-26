import CoreLocation
import Foundation
import HealthKit
import OSLog
import SwiftUI

@MainActor
@Observable
public class HealthSyncService: SyncService {
    
    private static nonisolated let identifier = "HealthSyncService"
    
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
    
    private static let supportedHealthKitTypes: Set<HKSampleType> = {
        var types: Set<HKSampleType> = [
            .workoutType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKSeriesType.workoutRoute()
        ]
        types.formUnion(WorkoutType.healthKitDistanceTypes)
        types.formUnion(WorkoutType.healthKitRepetitionTypes)
        return types
    }()
    
    public func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(toShare: Self.supportedHealthKitTypes, read: Self.supportedHealthKitTypes)
    }
    
    // MARK: Query
    
    /// Queries the workout with the given id assigned as `HKMetadataKeyExternalUUID` metadata.
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
    
    private func initializeRouteBuilder(for workout: RawWorkout, from workoutBuilder: HKWorkoutBuilder) -> HKWorkoutRouteBuilder? {
        guard !workout.route.isEmpty else { return nil }
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
        ofType type: HKQuantityType?,
        value: Double?,
        unit: HKUnit,
        for workout: RawWorkout,
        addTo collection: inout [HKQuantitySample]
    ) {
        guard let endDate = workout.endDate, let type, let value else { return }
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: workout.startDate, end: endDate, metadata: .none)
        collection.append(sample)
    }
    
    private func addQuanitySamples(for workout: RawWorkout, to workoutBuilder: HKWorkoutBuilder) async throws {
        var quantitySamples: [HKQuantitySample] = []
        createQuantitySample(
            ofType: workout.type.healthKitDistanceType,
            value: workout.distance,
            unit: .meter(),
            for: workout,
            addTo: &quantitySamples
        )
        createQuantitySample(
            ofType: .init(.activeEnergyBurned),
            value: workout.energy,
            unit: .joule(),
            for: workout,
            addTo: &quantitySamples
        )
        createQuantitySample(
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
        guard !workout.heartRates.isEmpty else { return }
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
        // TODO: Throw sensible error on missing endDate
        guard let endDate = workout.endDate else { throw SyncError.unknown }
        let config = config(for: workout.type.healthKitType)
        let workoutBuilder = initializeWorkoutBuilder(for: config)
        let routeBuilder = initializeRouteBuilder(for: workout, from: workoutBuilder)
        try await workoutBuilder.beginCollection(at: workout.startDate)
        try await addMetadata(for: workout, to: workoutBuilder)
        try await addWorkoutEvents(for: workout, to: workoutBuilder)
        try await addQuanitySamples(for: workout, to: workoutBuilder)
        try await addHeartRates(for: workout, to: workoutBuilder)
        try await addRouteData(for: workout, to: routeBuilder)
        try await workoutBuilder.endCollection(at: endDate)
        // TODO: Throw sensible error on nil
        guard let hkWorkout = try await workoutBuilder.finishWorkout() else { throw SyncError.unknown }
        // Against what the documentation says, the routeBuilder should not explicitly be finished through .finishRoute(with:,metadata:) as
        // this raises the error: com.apple.healthkit Code=3 "This route builder is attached to a workout builder and will be finished with
        // the workout builder"
        return hkWorkout
    }
    
    // MARK: Delete
    
    /// Deletes the given HealthKit workout and the associated objects.
    private func deleteHKWorkout(_ hkWorkout: HKWorkout) async throws {
        let associatedObjectPredicate = HKQuery.predicateForObjects(from: hkWorkout)
        for type in Self.supportedHealthKitTypes where type != .workoutType() {
            try await healthStore.deleteObjects(of: type, predicate: associatedObjectPredicate)
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

// TODO: Localize
enum HealthSyncServiceError: Error {
    case objectNotFound
}
