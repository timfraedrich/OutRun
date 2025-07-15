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
                // all other object 
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
    
    /*
    
    // MARK: - Workout
    
    /**
     This function saves a workout to the database.
     - parameter object: the data set to be saved to the database
     - parameter completion: the closure being executed on the main thread as soon as the saving either succeeds or fails
     - parameter success: indicates the success of saving the workout
     - parameter error: gives more detailed information on an error if one occured
     - parameter workout: holds the `Workout` if saving it succeeded
     - note: Objects conforming to `OREventInterface` and associated with the provided object will not be added to the database
     - warning: An `object` of Type `Workout` will be rejected with an `.alreadySaved` error, because all objects of that type must already be in the database.
     */
    public static func saveWorkout(
        object: ORWorkoutInterface,
        completion: @escaping (_ success: Bool, _ error: DataManager.SaveError?, _ workout: Workout?) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        saveWorkouts(
            objects: [object],
            completion: { success, error, workouts in
                if let workout = workouts.first {
                    completion(true, nil, workout)
                } else {
                    
                    switch error {
                    case .notAllSaved:
                        completion(false, .alreadySaved, nil)
                    case .notAllValid:
                        completion(false, .notValid, nil)
                    case .databaseError(let error):
                        completion(false, .databaseError(error: error), nil)
                    default:
                        // this case should never occur
                        completion(false, nil, nil)
                    }
                }
            }
        )
    }
    
    /**
     This function saves multiple workouts to the database.
     - parameter objects: the data sets to be saved to the database
     - parameter completion: the closure being executed on the main thread as soon as the saving either succeeds or fails
     - parameter success: indicates the success of saving workouts; this will also be `true` if not all workouts were valid and some have been excluded
     - parameter error: gives more detailed information on an error if one occured
     - parameter workouts: holds the `Workout`s that were successfully saved
     - note: Objects conforming to `OREventInterface` and associated with the provided objects will not be added to the database
     - warning: Objects of type `Workout` will be rejected, because all objects of that type must already be in the database.
     */
    public static func saveWorkouts(
        objects: [ORWorkoutInterface],
        completion: @escaping (_ success: Bool, _ error: DataManager.SaveMultipleError?, _ workouts: [Workout]) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        // filtering for Workout class and already saved
        let filteredObjects = objects.filter { (object) -> Bool in
            if object is Workout {
                return false
            } else if let uuid = object.uuid, objectHasDuplicate(uuid: uuid, objectType: Workout.self) {
                return false
            }
            return true
        }
        
        // Todo: Validation
        let validatedObjects = filteredObjects
        
        dataStack.perform(asynchronous: { (transaction) -> [Workout] in
            
            var workouts = [Workout]()
            
            for object in validatedObjects {
                
                let workout = transaction.create(Into<Workout>())
                workout._uuid .= object.uuid ?? UUID()
                workout._workoutType .= object.workoutType
                workout._distance .= object.distance
                workout._steps .= object.steps
                workout._startDate .= object.startDate
                workout._endDate .= object.endDate
                workout._burnedEnergy .= object.burnedEnergy
                workout._isRace .= object.isRace
                workout._comment .= object.comment
                workout._isUserModified .= object.isUserModified
                workout._healthKitUUID .= object.healthKitUUID
                
                workout._ascend .= object.ascend
                workout._descend .= object.descend
                workout._activeDuration .= object.activeDuration
                workout._pauseDuration .= object.pauseDuration
                workout._dayIdentifier .= object.dayIdentifier
                
                for tempPause in object.pauses {
                    let pause = transaction.create(Into<WorkoutPause>())
                    pause._uuid .= tempPause.uuid ?? UUID()
                    pause._startDate .= tempPause.startDate
                    pause._endDate .= tempPause.endDate
                    pause._pauseType .= tempPause.pauseType
                    
                    pause._workout .= workout
                }
                
                for tempWorkoutEvent in object.workoutEvents {
                    let workoutEvent = transaction.create(Into<WorkoutEvent>())
                    workoutEvent._uuid .= tempWorkoutEvent.uuid ?? UUID()
                    workoutEvent._eventType .= tempWorkoutEvent.eventType
                    workoutEvent._timestamp .= tempWorkoutEvent.timestamp
                    
                    workoutEvent._workout .= workout
                }

                for tempSample in object.routeData {
                    let routeSample = transaction.create(Into<WorkoutRouteDataSample>())
                    routeSample._uuid .= tempSample.uuid ?? UUID()
                    routeSample._latitude .= tempSample.latitude
                    routeSample._longitude .= tempSample.longitude
                    routeSample._altitude .= tempSample.altitude
                    routeSample._timestamp .= tempSample.timestamp
                    routeSample._horizontalAccuracy .= tempSample.horizontalAccuracy
                    routeSample._verticalAccuracy .= tempSample.verticalAccuracy
                    routeSample._speed .= tempSample.speed
                    routeSample._direction .= tempSample.direction
                    
                    routeSample._workout .= workout
                }
                
                for tempSample in object.heartRates {
                    let heartRateSample = transaction.create(Into<WorkoutHeartRateDataSample>())
                    heartRateSample._uuid .= tempSample.uuid ?? UUID()
                    heartRateSample._heartRate .= tempSample.heartRate
                    heartRateSample._timestamp .= tempSample.timestamp
                    
                    heartRateSample._workout .= workout
                }
                
                workouts.append(workout)
                
            }
            
            return workouts
            
        }) { (result) in
            switch result {
            case .success(let tempWorkouts):
                let workouts = dataStack.fetchExisting(tempWorkouts)
                
                if workouts.count == objects.count {
                    completion(true, nil, workouts)
                } else if workouts.count == filteredObjects.count {
                    completion(true, .notAllSaved, workouts)
                } else {
                    // last case: workouts.count must be equal to validatedObjects.count
                    completion(true, .notAllValid, workouts)
                }
                
            case .failure(let error):
                completion(false, .databaseError(error: error), [])
            }
        }
        
    }
    
    /**
     This function updates a workout from a data set referencing the workout with its universally unique identifier.
     - parameter object: the data set containing all updates
     - parameter completion: the closure being perfomed upon finishing the updating process
     - parameter success: indicates the success of the operation
     - parameter error: gives more detailed information on an error if one occured
     - parameter workout: holds the `Workout` if updating it succeeded
     - warning: Objects of type `Workout` will be rejected, because all objects of that type must already hold the provided data.
     */
    public static func updateWorkout(object: ORWorkoutInterface, completion: @escaping (_ success: Bool, _ error: DataManager.UpdateError?, _ workout: Workout?) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        // check for Workout class
        if object is Workout {
            completion(false, .notAltered, nil)
            return
        }
        
        // check for uuid {
        guard let uuid = object.uuid else {
            completion(false, .notSaved, nil)
            return
        }
        
        // Todo: Validation
        
        dataStack.perform(asynchronous: { (transaction) -> Workout? in
            
            if let workout = transaction.edit(queryObject(from: uuid, transaction: transaction) as Workout?) {
                
                workout._uuid .= object.uuid ?? UUID()
                workout._workoutType .= object.workoutType
                workout._distance .= object.distance
                workout._steps .= object.steps
                workout._startDate .= object.startDate
                workout._endDate .= object.endDate
                workout._burnedEnergy .= object.burnedEnergy
                workout._isRace .= object.isRace
                workout._comment .= object.comment
                workout._isUserModified .= object.isUserModified
                workout._healthKitUUID .= object.healthKitUUID
                
                workout._ascend .= object.ascend
                workout._descend .= object.descend
                workout._activeDuration .= object.activeDuration
                workout._pauseDuration .= object.pauseDuration
                workout._dayIdentifier .= object.dayIdentifier
                
                for tempPause in object.pauses where tempPause.uuid == nil {
                    let pause = transaction.create(Into<WorkoutPause>())
                    pause._uuid .= tempPause.uuid ?? UUID()
                    pause._startDate .= tempPause.startDate
                    pause._endDate .= tempPause.endDate
                    pause._pauseType .= tempPause.pauseType
                    
                    pause._workout .= workout
                }
                
                for tempWorkoutEvent in object.workoutEvents where tempWorkoutEvent.uuid == nil {
                    let workoutEvent = transaction.create(Into<WorkoutEvent>())
                    workoutEvent._uuid .= tempWorkoutEvent.uuid ?? UUID()
                    workoutEvent._eventType .= tempWorkoutEvent.eventType
                    workoutEvent._timestamp .= tempWorkoutEvent.timestamp
                    
                    workoutEvent._workout .= workout
                }

                for tempSample in object.routeData where tempSample.uuid == nil {
                    let routeSample = transaction.create(Into<WorkoutRouteDataSample>())
                    routeSample._uuid .= tempSample.uuid ?? UUID()
                    routeSample._latitude .= tempSample.latitude
                    routeSample._longitude .= tempSample.longitude
                    routeSample._altitude .= tempSample.altitude
                    routeSample._timestamp .= tempSample.timestamp
                    routeSample._horizontalAccuracy .= tempSample.horizontalAccuracy
                    routeSample._verticalAccuracy .= tempSample.verticalAccuracy
                    routeSample._speed .= tempSample.speed
                    routeSample._direction .= tempSample.direction
                    
                    routeSample._workout .= workout
                }
                
                for tempSample in object.heartRates where tempSample.uuid == nil {
                    let heartRateSample = transaction.create(Into<WorkoutHeartRateDataSample>())
                    heartRateSample._uuid .= tempSample.uuid ?? UUID()
                    heartRateSample._heartRate .= tempSample.heartRate
                    heartRateSample._timestamp .= tempSample.timestamp
                    
                    heartRateSample._workout .= workout
                }
                
                return workout
                
            } else {
                return nil
            }
            
        }) { (result) in
            switch result {
            case .success(let tempWorkout):
                if let tempWorkout = tempWorkout, let workout = dataStack.fetchExisting(tempWorkout) {
                    completion(true, nil, workout)
                } else {
                    completion(false, .databaseError(error: CoreStoreError.persistentStoreNotFound(entity: Workout.self)), nil)
                }
            case .failure(let error):
                completion(false, .databaseError(error: error), nil)
            }
        }
    }
    
    /**
     This function edits the reference to a HealthKit workout in the provided workout object.
     - parameter workout: the workout requiring a reference update
     - parameter reference: the reference being updated
     */
    public static func editHealthReference(for workout: ORWorkoutInterface, reference: UUID?) {
        
        dataStack.perform { transaction in
            
            guard let workout = queryObject(from: workout, transaction: transaction) as Workout? else { return }
            let edit = transaction.edit(workout)
            
            edit?._healthKitUUID .= reference
            
        } completion: { result in
            switch result {
            case .failure(let error):
                print("[DataManager] failed to create reference to health workout:", error.localizedDescription)
            default: break
            }
        }
    }
    
    /**
     This function looks up a workout object by searching for the provided UUID as being referenced in the `_healthKitUUID` property and updating it's reference value to `nil`
     - parameter reference: the reference that is supposed to be removed from a workout
     */
    public static func removeHealthReference(reference: UUID) {
        
        guard let workout: Workout = queryObject(from: \._healthKitUUID == reference) else { return }
        editHealthReference(for: workout, reference: nil)
    }
    
    // MARK: - Event
    
    /**
     Saves an event to the database.
     - parameter object: the data set to be saved to the database
     - parameter completion: the closure being executed on the main thread as soon as the saving either succeeds or fails
     - parameter success: indicates the success of saving the event
     - parameter error: gives more detailed information on an error if one occured
     - parameter event: holds the `Event` if saving it succeeded
     - note: Objects conforming to `ORWorkoutInterface` and associated with the provided data sets will not be added to the database, rather the data manager will try to query workout objects from only the provided `UUID`s in the `ORWorkoutInterface` objects and attach them to the `Event`. For that it is improtant that these workout objects are already saved to the database, otherwise a reference cannot be established.
     - warning: An `object` of Type `Event` will be rejected with an `.alreadySaved` error, because all objects of that type must already be in the database.
     */
    public static func saveEvent(object: OREventInterface, completion: @escaping (_ success: Bool, _ error: DataManager.SaveError?, _ event: Event?) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        saveEvents(
            objects: [object],
            completion: { success, error, events in
                if let event = events.first {
                    completion(true, nil, event)
                } else {
                    
                    switch error {
                    case .notAllSaved:
                        completion(false, .alreadySaved, nil)
                    case .notAllValid:
                        completion(false, .notValid, nil)
                    case .databaseError(let error):
                        completion(false, .databaseError(error: error), nil)
                    default:
                        // this case should never occur
                        completion(false, nil, nil)
                    }
                }
            }
        )
        
    }
    
    /**
     Saves multiple events to the database.
     - parameter objects: the data sets to be saved to the database
     - parameter completion: the closure being executed on the main thread as soon as the saving either succeeds or fails
     - parameter success: indicates the success of saving the events
     - parameter error: gives more detailed information on an error if one occured
     - parameter events: holds the `Event`s if saving them succeeded
     - note: Objects conforming to `ORWorkoutInterface` and associated with the provided data sets will not be added to the database, rather the data manager will try to query workout objects from only the provided `UUID`s in the `ORWorkoutInterface` objects and attach them to the `Event`s. For that it is improtant that these workout objects are already saved to the database, otherwise a reference cannot be established.
     - warning: `objects` of Type `Event` will be rejected with an `.alreadySaved` error, because all objects of that type must already be in the database.
     */
    public static func saveEvents(objects: [OREventInterface], completion: @escaping (_ success: Bool, _ error: DataManager.SaveMultipleError?, _ events: [Event]) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        let filteredObjects = objects.filter { (object) -> Bool in
            if object is Event {
                return false
            } else if let uuid = object.uuid, objectHasDuplicate(uuid: uuid, objectType: Event.self) {
                return false
            }
            return true
        }
        
        // Todo: Validation
        let validatedObjects = filteredObjects
        
        dataStack.perform(asynchronous: { (transaction) -> [Event] in
            
            var events = [Event]()
            
            for object in validatedObjects {
                
                let event = transaction.create(Into<Event>())
                
                event._uuid .= object.uuid ?? UUID()
                event._title .= object.title
                event._comment .= object.comment
                event._startDate .= object.startDate
                event._endDate .= object.endDate
                
                let workoutUUIDs = object.workouts.compactMap { (workout) -> UUID? in
                    return workout.uuid
                }
                
                if let workouts = try? transaction.fetchAll(
                    From<Workout>()
                        .where({
                            Where<Workout>(workoutUUIDs.containsOptional($0.uuid))
                        })
                        .orderBy(.ascending(\._startDate))
                ) {
                    event._workouts .= workouts
                }
                
                events.append(event)
                
            }
            
            return events
        
        }) { (result) in
            switch result {
            case .success(let tempEvents):
                let events = dataStack.fetchExisting(tempEvents)
                
                if events.count == objects.count {
                    completion(true, nil, events)
                } else if events.count == filteredObjects.count {
                    completion(true, .notAllSaved, events)
                } else {
                    // last case: workouts.count must be equal to validatedObjects.count
                    completion(true, .notAllValid, events)
                }
            case .failure(let error):
                completion(false, .databaseError(error: error), [])
            }
        }
    }
    
    /**
     This function updates an event from a data set referencing the event with its universally unique identifier.
     - parameter object: the data set containing all updates
     - parameter completion: the closure being perfomed upon finishing the updating process
     - parameter success: indicates the success of the operation
     - parameter error: gives more detailed information on an error if one occured
     - parameter event: holds the `Event` if updating it succeeded
     - warning: Objects of type `Event` will be rejected, because all objects of that type must already hold the provided data.
     */
    public static func updateEvent(object: OREventInterface, completion: @escaping (_ success: Bool, _ error: DataManager.UpdateError?, _ event: Event?) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        // check for Workout class
        if object is Event {
            completion(false, .notAltered, nil)
            return
        }
        
        // check for uuid {
        guard let uuid = object.uuid else {
            completion(false, .notSaved, nil)
            return
        }
        
        // Todo: Validation
        
        dataStack.perform(asynchronous: { (transaction) -> Event? in
            
            if let event = transaction.edit(queryObject(from: uuid, transaction: transaction) as Event?) {
                
                event._uuid .= object.uuid ?? UUID()
                event._title .= object.title
                event._comment .= object.comment
                event._startDate .= object.startDate
                event._endDate .= object.endDate
                
                for workoutObject in object.workouts {
                    
                    guard !(workoutObject is Workout), let uuid = workoutObject.uuid, let workout = transaction.edit(queryObject(from: uuid) as Workout?), !workout._events.contains(event) else {
                        continue
                    }
                    
                    var set = workout._events.value
                    set.insert(event)
                    workout._events .= set
                    
                }
                
                return event
                
            } else {
                return nil
            }
            
        }) { (result) in
            switch result {
            case .success(let tempEvent):
                if let tempEvent = tempEvent, let event = dataStack.fetchExisting(tempEvent) {
                    completion(true, nil, event)
                } else {
                    completion(false, .databaseError(error: CoreStoreError.persistentStoreNotFound(entity: Workout.self)), nil)
                }
            case .failure(let error):
                completion(false, .databaseError(error: error), nil)
            }
        }
        
    }
    
    // MARK: - Delete
    
    /**
     This function deletes an `ORDataType` object from the database.
     - parameter object: the object being deleted
     - parameter completion: the closure being perfomed upon finishing the deletion process
     - parameter success: indicates the success of the operation
     - parameter error: gives more detailed information on an error if one occured
     */
    public static func deleteObject<ObjectType: ORDataType>(object: ObjectType, completion: @escaping (_ success: Bool, _ error: DataManager.DeleteError?) -> Void) {
        
        dataStack.perform(asynchronous: { (transaction) -> Void in
            
            transaction.delete(object)
            
        }) { (result) in
            switch result {
            case .success(_):
                completion(true, nil)
            case .failure(let error):
                completion(false, .databaseError(error: error))
            }
        }
        
    }
    
    /**
     This function deletes all data objects in the database.
     - parameter completion: the closure being perfomed upon finishing the deletion process
     - parameter success: indicates the success of the operation
     - parameter error: gives more detailed information on an error if one occured
     */
    public static func deleteAll(completion: @escaping (_ success: Bool, _ error: DataManager.DeleteError?) -> Void) {
        
        dataStack.perform(asynchronous: { (transaction) -> Void in
            
            do {
                try transaction.deleteAll(From<Workout>())
                try transaction.deleteAll(From<WorkoutPause>())
                try transaction.deleteAll(From<WorkoutEvent>())
                try transaction.deleteAll(From<WorkoutRouteDataSample>())
                try transaction.deleteAll(From<WorkoutHeartRateDataSample>())
                try transaction.deleteAll(From<Event>())
            } catch {
                deletionError = error as? CoreStoreError
            }
            
        }) { (result) in
            switch result {
            case .success(_):
                if let error = deletionError {
                    completion(true, .databaseError(error: error))
                } else {
                    completion(true, nil)
                }
            case .failure(let error):
                completion(false, .databaseError(error: error))
            }
        }
            
    }
     */
}
