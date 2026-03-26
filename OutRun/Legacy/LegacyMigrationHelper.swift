import Foundation
import NIOCore
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
                while let rawWorkouts = try await manager.extractWorkoutBatch().map(RawWorkout.init) as Optional, rawWorkouts.count > 0 {
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
    
    /**
     Computes pauses from workout event data.
     - parameter events: The events from which the pauses are supposed to be calculated
     - parameter workoutStart: The start date of the workout to which the pauses are linked
     - parameter workoutEnd: The start date of the workout to which the pauses are linked
     - parameter minimumDuration: The minimum duration of a pause object. Objects with smaller duration will be filtered out. Provided
       values must be larger than 0.
     - returns: The calculated pause objects
     - complexity: O(*n* log *n*) in the number of events *n*.
     
     Workout event data might be inconsistent, in which case we try to recover pauses as follows:
     - Pauses that extend over the start or end of the workout (start...end) get trimmed at the start or end.
     - Overlapping pauses get merged if their types match
     - User initiated pauses take precedence over automatic pauses
     - Pauses of duration under 1s are ignored
     
     To illustrate, here is an example with user initiated (+) and automatic pauses (\*):
     ```
       start.................................end
     
       |---------------ORIGINAL----------------|
     
            +++++++             ++++
                         +++++++++
     ***     *****            *******        *****
     
       |---------------CONVERTED---------------|
     
            +++++++      +++++++++++         ***
     ```
     */
    static func calculatePauses(
        from events: [PauseEvent],
        workoutStart: Date,
        workoutEnd: Date,
        minimumDuration: TimeInterval = .leastNonzeroMagnitude
    ) -> [RawWorkoutPause] {
        let sortedEvents = events
            .map { PauseEvent(date: max(workoutStart, min(workoutEnd, $0.date)), type: $0.type) }
            .sorted { $0.date < $1.date }
        var pauses = [RawWorkoutPause]()
        var pauseStarts = CircularBuffer<Date>(initialCapacity: sortedEvents.count)
        var autoPauseStarts = CircularBuffer<Date>(initialCapacity: sortedEvents.count)
        for pauseEvent in sortedEvents {
            switch pauseEvent.type {
            case .pause:
                if pauseStarts.isEmpty, let firstAutoPauseStart = autoPauseStarts.first {
                    pauses.append(.init(startDate: firstAutoPauseStart, endDate: pauseEvent.date, userInitiated: false))
                }
                pauseStarts.append(pauseEvent.date)
            case .autoPause:
                autoPauseStarts.append(pauseEvent.date)
            case .resume:
                guard let start = pauseStarts.popLast(), pauseStarts.isEmpty else { continue }
                pauses.append(.init(startDate: start, endDate: pauseEvent.date, userInitiated: true))
            case .autoResume:
                guard let potentialStart = autoPauseStarts.popLast(), autoPauseStarts.isEmpty, pauseStarts.isEmpty else { continue }
                let start = if let lastPauseEnd = pauses.last?.endDate { max(potentialStart, lastPauseEnd) } else { potentialStart }
                pauses.append(.init(startDate: start, endDate: pauseEvent.date, userInitiated: false))
            }
        }
        if let pauseStart = pauseStarts.first {
            pauses.append(.init(startDate: pauseStart, endDate: workoutEnd, userInitiated: true))
        } else if let autoPauseStart = autoPauseStarts.first {
            pauses.append(.init(startDate: autoPauseStart, endDate: workoutEnd, userInitiated: false))
        }
        let safeMinimumDuration = max(minimumDuration, .leastNonzeroMagnitude)
        return pauses.filter { $0.duration >= safeMinimumDuration }
    }
    
    /// Converts a kcal energy value to a joules energy value. This is needed as legacy models use kcal for representing burned energy and
    /// new models from version 2.0.0 use joules
    static func convertKcalToJoules(_ kcal: Double) -> Double {
        UnitEnergy.kilocalories.converter.baseUnitValue(fromValue: kcal)
    }
    
    /// Returns a RawSyncServiceMapping for the WorkoutService .appleHealth if a healthKitUUID was provided or an empty array otherwise.
    static func serviceMappingsFromHealthKitUUID(_ healthKitUUID: UUID?) -> [RawSyncServiceMapping] {
        guard let healthKitUUID else { return [] }
        return [
            .init(
                serviceIdentifier: HealthSyncService.identifier,
                externalId: healthKitUUID.uuidString,
                externalUrl: nil,
                lastEditDateSynced: nil,
                syncStatus: .pending
            )
        ]
    }
    
    // MARK: Types
    
    struct PauseEvent {
        let date: Date
        let type: PauseEventType
        
        enum PauseEventType: Int {
            case pause = 0
            case autoPause = 1
            case resume = 2
            case autoResume = 3
            
            var isPauseStart: Bool {
                switch self {
                case .pause, .autoPause: true
                case .resume, .autoResume: false
                }
            }
            
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
    }
}
