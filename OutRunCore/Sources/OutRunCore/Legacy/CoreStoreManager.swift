import Combine
@preconcurrency import CoreStore
import Foundation

/// A structure holding static instances and methods for database management and manipulation
@MainActor
class CoreStoreManager<DataModel: CoreStoreDataModel> {
    
    private static var legacyFileName: String { "OutRun.sqlite" }
    
    static var legacyStorageExists: Bool {
        let storage = SQLiteStore(fileName: legacyFileName)
        return FileManager.default.fileExists(atPath: storage.fileURL.path())
    }
    
    /// The primary `DataStack` used by the `DataManager`.
    /// - warning: make sure `dataStack` is initialised by calling `DataManager.setup(dataModel:completion:migration:)` accessing the
    /// property will lead to a fatal error otherwise.
    private var dataStack: DataStack
    /// static optional instance of the local storage holding the workout data
    private var storage: SQLiteStore
    
    init(fileName: String = legacyFileName) async throws {
        storage = .init(
            fileName: fileName,
            migrationMappingProviders: DataModel.migrationChain.compactMap { $0.mappingProvider }
        )
        let migrationChain = DataModel.migrationChain
        guard let currentModel = migrationChain.last else { throw CoreStoreSetupError.failedToInitializeDataStack }
        let schemata = migrationChain.map { $0.schema }
        let versionIdentifiers = migrationChain.map { $0.identifier }
        var migrationDictionary: [String: String] = [:]
        for (index, element) in versionIdentifiers.enumerated().dropLast() {
            migrationDictionary[element] = versionIdentifiers[index + 1]
        }
        let schemaHistory = SchemaHistory(
            allSchema: schemata,
            migrationChain: .init(migrationDictionary),
            exactCurrentModelVersion: currentModel.identifier
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
    
    func extractAllWorkouts() async throws -> [RawDataModelV3.Workout] {
        guard DataModel.self == OutRunV3.self else { throw CoreStoreExtractionError.invalidModel }
        return try await withCheckedThrowingContinuation { continuation in
            dataStack.perform { transaction in
                // we only need to export workouts, as Event models were never used in production
                let csWorkouts = try transaction.fetchAll(From<OutRunV3.Workout>())
                return csWorkouts.map(RawDataModelV3.Workout.init)
            } success: { workouts in
                continuation.resume(returning: workouts)
            } failure: { error in
                continuation.resume(throwing: CoreStoreExtractionError.databaseError(error: error))
            }
        }
    }
    
    func close() async {
        await withCheckedContinuation { continuation in
            dataStack.unsafeRemoveAllPersistentStores {
                continuation.resume()
            }
        }
    }
    
    func deleteStorage() throws {
        try FileManager.default.removeItem(at: storage.fileURL)
    }
}

// MARK: - OutRunV1 Object Insertion

extension CoreStoreManager where DataModel == OutRunV1 {
    
    func insert(_ workouts: [RawDataModelV1.Workout]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            dataStack.perform { transaction in
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
            } success: { workouts in
                continuation.resume()
            } failure: { error in
                continuation.resume(throwing: CoreStoreInsertionError.databaseError(error: error))
            }
        }
    }
}

// MARK: - OutRunV2 Object Insertion

extension CoreStoreManager where DataModel == OutRunV2 {
    
    func insert(_ workouts: [RawDataModelV2.Workout]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            dataStack.perform { transaction in
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
            } success: { workouts in
                continuation.resume()
            } failure: { error in
                continuation.resume(throwing: CoreStoreInsertionError.databaseError(error: error))
            }
        }
    }
}

// MARK: - OutRunV3 Object Insertion

extension CoreStoreManager where DataModel == OutRunV3 {
    
    func insert(_ workouts: [RawDataModelV3.Workout]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            dataStack.perform { transaction in
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
            } success: { workouts in
                continuation.resume()
            } failure: { error in
                continuation.resume(throwing: CoreStoreInsertionError.databaseError(error: error))
            }
        }
    }
}
