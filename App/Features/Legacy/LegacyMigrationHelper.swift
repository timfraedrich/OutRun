//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import HealthKit
import OutRunCore
import OSLog
import SwiftData
import Perception
import AsyncAlgorithms

enum LegacyMigrationHelper {
    
    private static var defaultLegacyStorageFileName: String { "OutRun.sqlite" }
    private static let logger = Logger(category: "LegacyMigrationHelper")
    
    static var isLegacyMigrationAppropriate: Bool {
        LegacyDatabase<LegacyDataModelV3>.legacyStorageExists(for: defaultLegacyStorageFileName)
    }
    
    /// - parameter legalAcceptanceDate: The date the user accepted the current legal documents, recorded on the migrated user.
    static func performLegacyMigration(
        for legacyStorageFileName: String = defaultLegacyStorageFileName,
        core: OutRunCore,
        legalAcceptanceDate: Date
    ) -> (task: Task<Void, Never>?, progressStream: AsyncThrowingStream<Float, Error>) {
        let (stream, continuation) = AsyncThrowingStream<Float, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        continuation.yield(0)
        guard LegacyDatabase<LegacyDataModelV3>.legacyStorageExists(for: legacyStorageFileName) else {
            continuation.yield(1)
            continuation.finish()
            return (nil, stream)
        }
        let task = startMigrationTask(
            for: legacyStorageFileName,
            core: core,
            legalAcceptanceDate: legalAcceptanceDate,
            continuation: continuation
        )
        return (task, stream)
    }
    
    private static func startMigrationTask(
        for legacyStorageFileName: String,
        core: OutRunCore,
        legalAcceptanceDate: Date,
        continuation: AsyncThrowingStream<Float, Error>.Continuation
    ) -> Task<Void, Never> {
        Task(priority: .userInitiated) {
            do {
                try await migrationOperation(
                    for: legacyStorageFileName,
                    core: core,
                    legalAcceptanceDate: legalAcceptanceDate,
                    continuation: continuation
                )
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
    
    private static func migrationOperation(
        for legacyStorageFileName: String,
        core: OutRunCore,
        legalAcceptanceDate: Date,
        continuation: AsyncThrowingStream<Float, Error>.Continuation
    ) async throws {
        let coreStatusSequence = await MainActor.run { Perceptions { core.status }.buffer(policy: .unbounded) }
        for await status in coreStatusSequence where status == .needsSetup || status == .initialized {
            break
        }
        if await core.status == .needsSetup {
            let user = userFromLegacyUserPreferences(legalAcceptanceDate: legalAcceptanceDate)
            try await core.setup(for: user)
        } else {
            await MainActor.run { core.userPreferences?.recordLegalAcceptance(on: legalAcceptanceDate) }
        }
        let container = await core.modelContainer
        continuation.yield(0.05)
        let manager = try await LegacyDatabase<LegacyDataModelV3>(fileName: legacyStorageFileName)
        let workoutIDs = try manager.fetchWorkoutIDs()
        let totalCount = workoutIDs.count
        let maxConcurrentTasks = ProcessInfo.processInfo.activeProcessorCount
        let counter = AsyncCounter(value: 0)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, workoutID) in workoutIDs.enumerated() {
                if index >= maxConcurrentTasks {
                    try await group.next()
                }
                group.addTask {
                    guard let workout = manager.extractWorkout(with: workoutID) else { return }
                    try await migrateWorkout(.init(from: workout), into: container)
                    let count = await counter.increase()
                    continuation.yield(0.05 + 0.9 * Float(count) / Float(totalCount))
                }
            }
            try await group.waitForAll()
        }
        try await manager.deleteStorage()
        let exportToHealth = legacyUserPreference(for: "savesToAppleHealth", defaultValue: false)
        let importFromHealth = legacyUserPreference(for: "automaticallyImportNewHealthWorkouts", defaultValue: false)
        if exportToHealth || importFromHealth, let healthSyncService = await core.syncService(HealthSyncService.self) {
            if exportToHealth {
                await healthSyncService.setOutwardSyncMode(.enabled)
            }
            if importFromHealth {
                await healthSyncService.setInwardSyncMode(.enabled)
            }
        }
        continuation.yield(1)
    }
    
    private static func migrateWorkout(_ rawWorkout: RawWorkout, into container: ModelContainer) async throws {
        let context = ModelContext(container)
        var rawWorkout = rawWorkout
        // Check if source is App or Apple Health
        // -> YES (or UNKNOWN): Keep source as .native
        // -> NO: Set source as .syncService(HealthSyncService.identifier)
        let mappingIndex = rawWorkout.serviceMappings.firstIndex { $0.serviceIdentifier == HealthSyncService.identifier }
        if let mappingIndex,
           let healthWorkoutID = rawWorkout.serviceMappings[safeIndex: mappingIndex]?.externalId,
           let healthWorkoutUUID = UUID(uuidString: healthWorkoutID),
           await !isHealthWorkoutNative(healthWorkoutUUID) {
            rawWorkout.source = .syncService(identifier: HealthSyncService.identifier)
        }
        let workout = Workout(from: rawWorkout)
        workout.route = rawWorkout.route.map { WorkoutRouteDataSample.init(from: $0) }
        workout.heartRates = rawWorkout.heartRates.map { WorkoutHeartRateDataSample(from: $0) }
        workout.pauses = rawWorkout.pauses.map { WorkoutPause(from: $0) }
        workout.events = rawWorkout.events.map { WorkoutEvent(from: $0) }
        workout.serviceMappings = rawWorkout.serviceMappings.map { SyncServiceMapping(from: $0) }
        context.insert(workout)
        try context.save()
    }
    
    private static func userFromLegacyUserPreferences(legalAcceptanceDate: Date) -> RawUser {
        let userPreferences = UserPreferences(preferences: [:])
        userPreferences.recordLegalAcceptance(on: legalAcceptanceDate)
        userPreferences.defaultWorkoutType = legacyUserPreference(for: "standardWorkoutType").map(WorkoutType.init(legacyRawValue:))
        userPreferences.requiredGPSAccuracy = legacyUserPreference(for: "gpsAccuracy") ?? UserPreferences.defaultGPSAccuracy
        userPreferences.calculateRollingSpeed = legacyUserPreference(for: "makeSpeedDisplayRolling") ?? false
        userPreferences.distanceUnit = legacyUserPreference(for: "distanceMeasurementType", possibleValues: [.kilometers, .miles])
        userPreferences.altitudeUnit = legacyUserPreference(for: "altitudeMeasurementType", possibleValues: [.meters, .feet])
        userPreferences.speedUnit = legacyUserPreference(for: "speedMeasurementType", possibleValues: [.kilometersPerHour, .milesPerHour])
        userPreferences.energyUnit = legacyUserPreference(for: "energyMeasurementType", possibleValues: [.kilojoules, .kilocalories])
        userPreferences.weightUnit = legacyUserPreference(for: "weightMeasurementType", possibleValues: [.kilograms, .pounds])
        let userName = legacyUserPreference(for: "name") ?? String(localized: "legacy_migration_user")
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

    /// Fetches the HKHealthStore for the provided HKWorkout UUID and returns whether the workout source is OutRun.
    ///
    /// - note: The default return value, if the health workout cannot be found is `false`.
    ///
    /// The default values was chosen as `false`. We therefore assume a workout to be imported from Health if we cannot find it. We applied
    /// the following reasoning to come to the decision:
    ///
    /// The event that a workout cannot be found in Health can
    /// only happen in two cases:
    ///   - **The workout was deleted** - Here we can distinguish into two further cases:
    ///     - **The workout was created in OutRun** - The assumption is false. We prevent the user from exporting this natively recorded
    ///     workout to Health in the future. This compromise was accepted since the user decided to delete the workout in Health on their
    ///     own accord and assuming a native workout would lead to more significant problems in the other cases.
    ///     - **The workout was imported from Health** - In this case the assumption was correct. If the user attempts to import the workout
    ///     again it will yield and error (which is correct behaviour). If we were to assume it is native instead, the workout will still
    ///     not be found on the next sync run and therefore saved to Health again, even though the user deleted it already.
    ///   - **Access to the workout was revoked** - Since an app always retains access to it's own workouts, the workout must be from
    ///   another app. The same logic as for deleted workouts from other apps applies: In this case we get duplicate of the workout in
    ///   Health. The user may decide to give access to the workout back to this app, restoring the health functionality fully.
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
        return false
    }
}
