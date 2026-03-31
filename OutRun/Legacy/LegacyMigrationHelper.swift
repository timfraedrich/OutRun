import Foundation
import HealthKit
import OutRunCore
import OSLog
import SwiftData
import Perception

enum LegacyMigrationHelper {
    
    private static var legacyStorageFileName: String { "OutRun.sqlite" }
    private static let logger = Logger(subsystem: "de.tadris.OutRun", category: "LegacyMigrationHelper")
    
    static var isLegacyMigrationAppropriate: Bool {
        LegacyDatabase<LegacyDataModelV3>.legacyStorageExists(for: legacyStorageFileName)
    }
    
    static func performLegacyMigration(
        for legacyStorageFileName: String = legacyStorageFileName,
        core: OutRunCore
    ) -> (task: Task<Void, Never>?, progressStream: AsyncThrowingStream<Float, Error>) {
        let (stream, continuation) = AsyncThrowingStream<Float, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.yield(0)
        guard LegacyDatabase<LegacyDataModelV3>.legacyStorageExists(for: legacyStorageFileName) else {
            continuation.yield(1)
            continuation.finish()
            return (nil, stream)
        }
        let task = Task(priority: .high) {
            do {
                let coreStatusSequence = await MainActor.run { Perceptions { core.status }.buffer(policy: .unbounded) }
                for await status in coreStatusSequence where status == .needsSetup || status == .initialized {
                    break
                }
                if await core.status == .needsSetup {
                    let user = userFromLegacyUserPreferences()
                    try await core.setup(for: user)
                }
                continuation.yield(0.05)
                let manager = try await LegacyDatabase<LegacyDataModelV3>(fileName: legacyStorageFileName)
                let totalCount = try await manager.fetchWorkoutCount()
                var count = 0
                while var rawWorkouts = try await manager.extractWorkoutBatch().map(RawWorkout.init) as Optional, rawWorkouts.count > 0 {
                    // Check if source is App or Apple Health
                    // -> YES (or UNKNOWN): Keep source as .native
                    // -> NO: Set source as .syncService(HealthSyncService.identifier)
                    for index in rawWorkouts.indices {
                        var rawWorkout = rawWorkouts[index]
                        let serviceIdentifier = HealthSyncService.identifier
                        let mappingIndex = rawWorkout.serviceMappings.firstIndex(where: { $0.serviceIdentifier == serviceIdentifier })
                        guard let mappingIndex,
                              let healthWorkoutID = rawWorkout.serviceMappings[safeIndex: mappingIndex]?.externalId,
                              let healthWorkoutUUID = UUID(uuidString: healthWorkoutID),
                              await !isHealthWorkoutNative(healthWorkoutUUID)
                        else { continue }
                        rawWorkout.source = .syncService(identifier: serviceIdentifier)
                        rawWorkouts[index] = rawWorkout
                    }
                    // Insert into new database
                    try await core.insert(rawWorkouts)
                    try await manager.deleteWorkoutBatch()
                    count += 10
                    continuation.yield(0.05 + 0.9 * Float(count) / Float(totalCount))
                }
                try await manager.deleteStorage()
                continuation.yield(1)
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        return (task, stream)
    }
    
    private static func userFromLegacyUserPreferences() -> RawUser {
        let userPreferences = UserPreferences(preferences: [:])
        userPreferences.defaultWorkoutType = legacyUserPreference(for: "standardWorkoutType").map(WorkoutType.init(rawValue:))
        userPreferences.requiredGPSAccuracy = legacyUserPreference(for: "gpsAccuracy") ?? UserPreferences.defaultGPSAccuracy
        userPreferences.calculateRollingSpeed = legacyUserPreference(for: "makeSpeedDisplayRolling") ?? false
        userPreferences.distanceUnit = legacyUserPreference(for: "distanceMeasurementType", possibleValues: [.kilometers, .miles])
        userPreferences.altitudeUnit = legacyUserPreference(for: "altitudeMeasurementType", possibleValues: [.meters, .feet])
        userPreferences.speedUnit = legacyUserPreference(for: "speedMeasurementType", possibleValues: [.kilometersPerHour, .milesPerHour])
        userPreferences.energyUnit = legacyUserPreference(for: "energyMeasurementType", possibleValues: [.kilojoules, .kilocalories])
        userPreferences.weightUnit = legacyUserPreference(for: "weightMeasurementType", possibleValues: [.kilograms, .pounds])
        let userName = legacyUserPreference(for: "name") ?? R.string.localizable.legacy_migration_user()
        let userWeight: Double? = legacyUserPreference(for: "weight")
        return RawUser(name: userName, birthday: nil, weight: userWeight, sex: nil, preferences: userPreferences.preferences, creationDate: .now)
    }
    
    private static func legacyUserPreference<T>(for key: String) -> T? {
        UserDefaults.standard.object(forKey: key) as? T
    }
    
    private static func legacyUserPreference<T>(for key: String, defaultValue: T) -> T {
        legacyUserPreference(for: key) ?? defaultValue
    }
    
    private static func legacyUserPreference<U: Dimension>(for key: String, possibleValues: [U]) -> U? {
        let index: Int? = legacyUserPreference(for: key)
        return possibleValues[safeIndex: index]
    }
    
    /// Converts a kcal energy value to a joules energy value. This is needed as legacy models use kcal for representing burned energy and
    /// new models from version 2.0.0 use joules
    static func convertKcalToJoules(_ kcal: Double) -> Double {
        UnitEnergy.kilocalories.converter.baseUnitValue(fromValue: kcal)
    }
    
    /// Returns a RawSyncServiceMapping for the WorkoutService .appleHealth if a healthKitUUID was provided or an empty array otherwise.
    static func serviceMappingsFromHealthKitUUID(_ healthKitUUID: UUID?, lastEditDate: Date) -> [RawSyncServiceMapping] {
        guard let healthKitUUID else { return [] }
        return [
            .init(
                serviceIdentifier: HealthSyncService.identifier,
                externalId: healthKitUUID.uuidString,
                externalUrl: nil,
                lastEditDateSynced: lastEditDate,
                syncStatus: .synced
            )
        ]
    }

    /// Fetches the HKHealthStore for the provided HKWorkout UUID and returns whether it is native. The default return value, if the health
    /// workout cannot be found is `true`.
    private static func isHealthWorkoutNative(_ healthWorkoutUUID: UUID) async -> Bool {
        do {
            let store = HKHealthStore()
            let uuidPredicate = HKQuery.predicateForObject(with: healthWorkoutUUID)
            let samplePredicate = HKSamplePredicate.workout(uuidPredicate)
            let descriptor = HKSampleQueryDescriptor(predicates: [samplePredicate], sortDescriptors: [], limit: 1)
            guard let workout = try await descriptor.result(for: store).first else { throw HKError(.errorNoData) }
            return workout.sourceRevision.source == .default()
        } catch {
            logger.error("Failed to fetch workout with health store id \(healthWorkoutUUID): \(error.localizedDescription)")
        }
        return true
    }
}

extension Calculation.PauseEventType {
    
    init?(legacyEventType: LegacyWorkoutEventType) {
        switch legacyEventType {
        case .pause: self = .pause
        case .autoPause: self = .autoPause
        case .resume: self = .resume
        case .autoResume: self = .autoResume
        default: return nil
        }
    }
}
