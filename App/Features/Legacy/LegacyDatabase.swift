import Combine
import CoreStore
import Foundation

/// A structure holding static instances and methods for database management and manipulation
@MainActor
class LegacyDatabase<DataModel: LegacyDataModel> {
    
    nonisolated static func legacyStorageURL(for filename: String) -> URL {
        SQLiteStore(fileName: filename).fileURL
    }
    
    nonisolated static func legacyStorageExists(for filename: String) -> Bool {
        let legacyStorageURL = legacyStorageURL(for: filename)
        return FileManager.default.fileExists(atPath: legacyStorageURL.relativePath)
    }
    
    /// The primary `DataStack` used by the `DataManager`.
    /// - warning: make sure `dataStack` is initialised by calling `DataManager.setup(dataModel:completion:migration:)` accessing the
    /// property will lead to a fatal error otherwise.
    private var dataStack: DataStack
    /// static optional instance of the local storage holding the workout data
    private var storage: SQLiteStore
    
    init(fileName: String) async throws {
        storage = .init(
            fileName: fileName,
            migrationMappingProviders: DataModel.migrationChain.compactMap { $0.mappingProvider }
        )
        let migrationChain = DataModel.migrationChain
        let schemata = migrationChain.map { $0.schema }
        let versionIdentifiers = migrationChain.map { $0.identifier }
        var migrationDictionary: [String: String] = [:]
        for (index, element) in versionIdentifiers.enumerated().dropLast() {
            migrationDictionary[element] = versionIdentifiers[index + 1]
        }
        let schemaHistory = SchemaHistory(
            allSchema: schemata,
            migrationChain: .init(migrationDictionary),
            exactCurrentModelVersion: DataModel.identifier
        )
        dataStack = .init(schemaHistory: schemaHistory)
        try await withCheckedThrowingContinuation { continuation in
            _ = dataStack.addStorage(storage, completion: { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
    
    func close() async {
        await withCheckedContinuation { continuation in
            dataStack.unsafeRemoveAllPersistentStores {
                continuation.resume()
            }
        }
    }
    
    func storageExistsOnDisk() -> Bool {
        FileManager.default.fileExists(atPath: storage.fileURL.relativePath)
    }
    
    func deleteStorage() throws {
        try FileManager.default.removeItem(at: storage.fileURL)
    }
}

// MARK: - OutRunV1 Object Insertion

extension LegacyDatabase where DataModel == LegacyDataModelV1 {
    
    func insert(_ workouts: [LegacyRawDataModelV1.Workout]) async throws {
        try await MainActor.run {
            let transaction = dataStack.beginUnsafe()
            for rawWorkout in workouts {
                
                let workout = transaction.create(Into<DataModel.Workout>())
                workout.uuid .= rawWorkout.uuid ?? UUID()
                workout.workoutType .= rawWorkout.workoutType
                workout.distance .= rawWorkout.distance
                workout.startDate .= rawWorkout.startDate
                workout.endDate .= rawWorkout.endDate
                workout.burnedEnergy .= rawWorkout.burnedEnergy
                workout.healthKitUUID .= rawWorkout.healthKitUUID
                
                for rawRouteSample in rawWorkout.locations {
                    let routeSample = transaction.create(Into<DataModel.RouteDataSample>())
                    routeSample.id .= rawRouteSample.uuid ?? UUID()
                    routeSample.latitude .= rawRouteSample.latitude
                    routeSample.longitude .= rawRouteSample.longitude
                    routeSample.altitude .= rawRouteSample.altitude
                    routeSample.timestamp .= rawRouteSample.timestamp
                    routeSample.speed .= rawRouteSample.speed
                    routeSample.direction .= rawRouteSample.direction
                    routeSample.workout .= workout
                }
            }
            try transaction.commitAndWait()
        }
    }
}

// MARK: - OutRunV2 Object Insertion

extension LegacyDatabase where DataModel == LegacyDataModelV2 {
    
    func insert(_ workouts: [LegacyRawDataModelV2.Workout]) async throws {
        try await MainActor.run {
            let transaction = dataStack.beginUnsafe()
            for rawWorkout in workouts {
                
                let workout = transaction.create(Into<DataModel.Workout>())
                workout.uuid .= rawWorkout.uuid ?? UUID()
                workout.workoutType .= rawWorkout.workoutType
                workout.distance .= rawWorkout.distance
                workout.startDate .= rawWorkout.startDate
                workout.endDate .= rawWorkout.endDate
                workout.burnedEnergy .= rawWorkout.burnedEnergy
                workout.isRace .= rawWorkout.isRace
                workout.comment .= rawWorkout.comment
                workout.isUserModified .= rawWorkout.isUserModified
                workout.healthKitUUID .= rawWorkout.healthKitUUID
                
                for rawRouteSample in rawWorkout.locations {
                    let routeSample = transaction.create(Into<DataModel.RouteDataSample>())
                    routeSample.uuid .= rawRouteSample.uuid ?? UUID()
                    routeSample.latitude .= rawRouteSample.latitude
                    routeSample.longitude .= rawRouteSample.longitude
                    routeSample.altitude .= rawRouteSample.altitude
                    routeSample.timestamp .= rawRouteSample.timestamp
                    routeSample.horizontalAccuracy .= rawRouteSample.horizontalAccuracy
                    routeSample.verticalAccuracy .= rawRouteSample.verticalAccuracy
                    routeSample.speed .= rawRouteSample.speed
                    routeSample.direction .= rawRouteSample.direction
                    routeSample.workout .= workout
                }
            }
            try transaction.commitAndWait()
        }
    }
}

// MARK: - OutRunV3 Object Insertion

extension LegacyDatabase where DataModel == LegacyDataModelV3 {
    
    func insert(_ workouts: [LegacyRawDataModelV3.Workout]) async throws {
        try await MainActor.run {
            let transaction = dataStack.beginUnsafe()
            for rawWorkout in workouts {
                
                let workout = transaction.create(Into<DataModel.Workout>())
                workout.uuid .= rawWorkout.uuid ?? UUID()
                workout.workoutType .= rawWorkout.workoutType
                workout.distance .= rawWorkout.distance
                workout.steps .= rawWorkout.steps
                workout.startDate .= rawWorkout.startDate
                workout.endDate .= rawWorkout.endDate
                workout.burnedEnergy .= rawWorkout.burnedEnergy
                workout.isRace .= rawWorkout.isRace
                workout.comment .= rawWorkout.comment
                workout.isUserModified .= rawWorkout.isUserModified
                workout.healthKitUUID .= rawWorkout.healthKitUUID
                
                for rawRouteSample in rawWorkout.locations {
                    let routeSample = transaction.create(Into<DataModel.WorkoutRouteDataSample>())
                    routeSample.uuid .= rawRouteSample.uuid ?? UUID()
                    routeSample.latitude .= rawRouteSample.latitude
                    routeSample.longitude .= rawRouteSample.longitude
                    routeSample.altitude .= rawRouteSample.altitude
                    routeSample.timestamp .= rawRouteSample.timestamp
                    routeSample.horizontalAccuracy .= rawRouteSample.horizontalAccuracy
                    routeSample.verticalAccuracy .= rawRouteSample.verticalAccuracy
                    routeSample.speed .= rawRouteSample.speed
                    routeSample.direction .= rawRouteSample.direction
                    routeSample.workout .= workout
                }
                
                for rawEvent in rawWorkout.workoutEvents {
                    let event = transaction.create(Into<DataModel.WorkoutEvent>())
                    event.uuid .= rawEvent.uuid ?? UUID()
                    event.startDate .= rawEvent.startDate
                    event.endDate .= rawEvent.endDate
                    event.eventType .= rawEvent.eventType
                    event.workout .= workout
                }
                
                for rawHeartRateSample in rawWorkout.heartRates {
                    let heartRateSample = transaction.create(Into<DataModel.WorkoutHeartRateDataSample>())
                    heartRateSample.uuid .= rawHeartRateSample.uuid ?? UUID()
                    heartRateSample.heartRate .= rawHeartRateSample.heartRate
                    heartRateSample.timestamp .= rawHeartRateSample.timestamp
                    heartRateSample.workout .= workout
                }
            }
            try transaction.commitAndWait()
        }
    }
    
    @MainActor
    func fetchWorkoutCount() throws -> Int {
        try dataStack.fetchCount(From<LegacyDataModelV3.Workout>())
    }
    
    @MainActor
    func extractWorkout(at offset: Int) throws -> LegacyRawDataModelV3.Workout? {
        let fetchClause = From<DataModel.Workout>().tweak { query in
            query.fetchLimit = 1
            query.fetchOffset = offset
        }
        return try dataStack.fetchAll(fetchClause).first.map(LegacyRawDataModelV3.Workout.init)
    }
}
