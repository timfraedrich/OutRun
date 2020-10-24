//
//  DataManager.swift
//
//  OutRun
//  Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import CoreStore
import CoreLocation
import HealthKit

struct DataManager {
    
    /// static optional instance of the local storage holding the workout data
    private static var storage: SQLiteStore?
    
    /// the optional size of the local storage in bytes
    public static var diskSize: Int? {
        if let size = storage?.fileSize() {
            return Int(size)
        }
        return nil
    }
    
    /**
     The primary `DataStack` used by the `DataManager`.
     - warning: make sure `dataStack` is initialised by calling `DataManager.setup(dataModel:completion:migration:)` accessing the property will lead to a fatal error otherwise
     */
    public static var dataStack: DataStack!
    
    /**
     This function sets up the data management by initialising the `dataStack` and loading the underlying sqlite storage of the database
     - parameter dataModel: an `ORDataModel` conforming `Type` being used to setup the data management
     - parameter completion: the closure being called on a successful completion of setting up data management
     - parameter migration: the closure being called on the event of a migration happening, including a `Progress` object indicating the progress of the migration
     - warning: If this method fails it does so in a fatal error, the app will crash as a result.
     */
    static func setup(dataModel: ORDataModel.Type, completion: @escaping (DataManager.SetupError?) -> Void, migration: @escaping (Progress) -> Void) {
        
        
        let completion: (DataManager.SetupError?) -> Void = { error in
            DispatchQueue.main.async {
                completion(error)
            }
        }
        
        // setup storage
        let storage = SQLiteStore(
            fileName: "OutRun.sqlite",
            migrationMappingProviders: dataModel.migrationChain.compactMap(
                { (type) -> CustomSchemaMappingProvider? in
                    return type.mappingProvider
                }
            ),
            localStorageOptions: .none
        )
        
        // select relevant versions
        let currentVersion = storage.currentORModel(from: dataModel.migrationChain)
        var relevants = dataModel.migrationChain.filter { (type) -> Bool in
            // relevent version should include the final type (dataModel) and all intermediate models, but it is important that they are successors of current version of the storage otherwise the models might be incompatible
            (type.self is ORIntermediateDataModel.Type || type == dataModel) && (currentVersion != nil ? type.isSuccessor(to: currentVersion!) : true)
        }
            
        let destinationModel = relevants.removeFirst()
        dataStack = DataStack(oRMigrationChain: dataModel.migrationChain, oRDataModel: destinationModel)
        
        // adding storage
        if let progress = dataStack.addStorage(
            storage,
            completion: { result in
                switch result {
                case .success(_):
                    
                    if let intermediate = destinationModel as? ORIntermediateDataModel.Type {
                        if !intermediate.intermediateMappingActions(dataStack) {
                            print("[DataManager] Intermediate mapping actions of \(destinationModel) were unsuccessful")
                            completion(.intermediateMappingActionsFailed(version: intermediate))
                            return
                        }
                    }
                    
                    if relevants.first != nil {
                        setup(dataModel: dataModel, completion: completion, migration: migration)
                    } else {
                        completion(nil)
                    }
                    
                case .failure(let error):
                    print("[DataManager] Failed to add storage for \(dataModel)\nError: \(error)")
                    completion(.failedToAddStorage(error: error))
                }
            }
        ) {
            // handling migration
            DispatchQueue.main.async {
                migration(progress)
            }
        }
    }
    
    /**
     This function saves a workout to the database.
     - parameter object: the data set to be saved to the database
     - parameter completion: the closure being executed on the main thread as soon as the saving either succeeds or fails
        - success: indicates the success
        - error: gives more detailed information on an error if one occured
        - workout: holds the `Workout` if saving it succeeded
     - warning: An `object` of Type `Workout` will be rejected with an `.alreadySaved` error, because all objects of that type must already be in the database.
     */
    static func saveWorkout(
        object: ORWorkoutInterface,
        completion: @escaping (Bool, DataManager.SaveError?, Workout?) -> Void) {
        
        let completion: (Bool, DataManager.SaveError?, Workout?) -> Void = { success, error, workout in
            DispatchQueue.main.async {
                completion(success, error, workout)
            }
        }
        
        // checking for Workout class
        if object is Workout {
            completion(false, .alreadySaved, nil)
            return
        }
        
        // checking if already saved
        if let uuid = object.uuid, workoutHasDuplicate(uuid: uuid) {
            completion(false, .alreadySaved, nil)
            return
        }
        
        // Todo: Validation
        
        dataStack.perform(asynchronous: { (transaction) -> Workout in
            
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
            
            return workout
            
        }) { (result) in
            switch result {
            case .success(let tempWorkout):
                let workout = dataStack.fetchExisting(tempWorkout)
                completion(true, nil, workout)
            case .failure(let error):
                completion(false, .databaseError(error: error), nil)
            }
        }
    }
    
    // TODO: save multiple workouts; alter workout; save event; save events; delete all
    
    /// A `CoreStore.ListMonitor` to observe changes in the database and refresh the `WorkoutListViewController`
    static let workoutMonitor = dataStack.monitorList(
        From<Workout>()
            .orderBy(.descending(\._startDate))
            .where(Where<Workout>(true))
    )
    
}
