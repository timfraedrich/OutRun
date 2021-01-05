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
    
    public static var dataStack = DataStack(
        OutRunV1.schema,
        OutRunV2.schema,
        OutRunV3.schema,
        migrationChain: [OutRunV1.identifier, OutRunV2.identifier, OutRunV3.identifier]
    )
    
    // MARK: Setup
    static func setup(completion: @escaping () -> Void, migrationClosure: @escaping () -> ((Double) -> Void)) {
        
        let storage = SQLiteStore(
            fileName: "OutRun.sqlite",
            migrationMappingProviders: [
                OutRunV2.mappingProvider,
                OutRunV3.mappingProvider
            ],
            localStorageOptions: .none
        )
        
        self.storage = storage
        
        if let migrationProgress = dataStack.addStorage(storage, completion: { (result) in
            switch result {
            case .success(let storage):
                print("Successfully added storage:", storage)
                
                DispatchQueue.main.async {
                    completion()
                }
                
            case .failure(let error):
                fatalError(error.debugDescription)
            }
        }) {
            // Handle Migration
            DispatchQueue.main.async {
                let progressClosure = migrationClosure()
                
                migrationProgress.setProgressHandler { (progress) in
                    DispatchQueue.main.async {
                        progressClosure(progress.fractionCompleted)
                    }
                }
            }
            
        }
    }
    
    // MARK: Save Workout
    static func saveWorkout(
        withType type: Workout.WorkoutType,
        start startDate: Date,
        end endDate: Date,
        distance: Double,
        steps: Int? = nil,
        isRace: Bool = false,
        isUserModified: Bool = false,
        comment: String? = nil,
        burnedEnergy: Double? = nil,
        healthKitUUID: UUID? = nil,
        events tempEvents: [TempWorkoutEvent],
        routeSamples tempRouteSamples: [TempWorkoutRouteDataSample],
        heartRates: [TempWorkoutHeartRateDataSample],
        completion: @escaping (Bool, Error?, Workout?) -> Void) {
        
        dataStack.perform(asynchronous: { (transaction) -> Workout in
            
            let workout = transaction.create(Into<Workout>())
            workout.uuid .= UUID()
            workout.workoutType .= type.rawValue
            workout.startDate .= startDate
            workout.endDate .= endDate
            workout.distance .= distance
            workout.steps .= steps
            workout.isRace .= isRace
            workout.isUserModified .= isUserModified
            workout.comment .= comment
            
            if let burnedEnergy = burnedEnergy {
                workout.burnedEnergy .= burnedEnergy
            } else if UserPreferences.weight.value != nil {
                workout.burnedEnergy .= BurnedEnergyCalculator.calculateBurnedCalories(for: type, distance: distance, weight: UserPreferences.weight.value!).doubleValue
            }
            
            if healthKitUUID != nil {
                workout.healthKitUUID .= healthKitUUID
            }
            
            for tempEvent in tempEvents {
                let event = transaction.create(Into<WorkoutEvent>())
                event.uuid .= tempEvent.uuid ?? UUID()
                event.eventType .= tempEvent.eventType
                event.startDate .= tempEvent.startDate
                event.endDate .= tempEvent.endDate
                event.workout .= workout
            }

            for tempSample in tempRouteSamples {
                let sample = transaction.create(Into<WorkoutRouteDataSample>())
                sample.uuid .= tempSample.uuid ?? UUID()
                sample.latitude .= tempSample.latitude
                sample.longitude .= tempSample.longitude
                sample.altitude .= tempSample.altitude
                sample.timestamp .= tempSample.timestamp
                sample.horizontalAccuracy .= tempSample.horizontalAccuracy
                sample.verticalAccuracy .= tempSample.verticalAccuracy
                sample.speed .= tempSample.speed
                sample.direction .= tempSample.direction
                sample.workout .= workout
            }
            
            for heartRate in heartRates {
                let sample = transaction.create(Into<WorkoutHeartRateDataSample>())
                sample.uuid .= heartRate.uuid ?? UUID()
                sample.heartRate .= heartRate.heartRate
                sample.timestamp .= heartRate.timestamp
                sample.workout .= workout
            }
            
            return workout
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let tempWorkout):
                    let workout = dataStack.fetchExisting(tempWorkout)
                    completion(true, nil, workout)
                case .failure(let error):
                    completion(false, error, nil)
                }
            }
        }
    }
    
    static func saveWorkout(for hkQueryObject: HKWorkoutQueryObject, completion: @escaping (Bool, Error?, Workout?) -> Void) {
        DataManager.saveWorkouts(
            for: [hkQueryObject],
            completion: { (success, error, workouts) in
                completion(success, error, workouts.first)
            }
        )
    }
    
    static func saveWorkouts(for hkQueryObjects: [HKWorkoutQueryObject], completion: @escaping (Bool, Error?, [Workout]) -> Void) {
        
        dataStack.perform(asynchronous: { (transaction) -> [Workout] in
            
            var tempWorkouts = [Workout]()
            
            let hkQueryObjects = hkQueryObjects.filter { (queryObject) -> Bool in
                return !DataQueryManager.checkForDuplicateHealthWorkout(withUUID: queryObject.hkWorkout.uuid)
            }
            
            for (index, object) in hkQueryObjects.enumerated() {
                
                print("importing hk workout:", index)
                
                let workout = transaction.create(Into<Workout>())
                workout.uuid .= UUID()
                workout.workoutType .= object.type.rawValue
                workout.startDate .= object.startDate
                workout.endDate .= object.endDate
                workout.distance .= object.distance.converting(to: UnitLength.meters).value
                workout.steps .= object.steps
                workout.isUserModified .= object.isUserEntered
                workout.healthKitUUID .= object.hkWorkout.uuid
                
                if let burnedEnergy = object.energyBurned {
                    workout.burnedEnergy .= burnedEnergy.converting(to: UnitEnergy.kilocalories).value
                } else if UserPreferences.weight.value != nil {
                    workout.burnedEnergy .= BurnedEnergyCalculator.calculateBurnedCalories(for: object.type, distance: object.distance.converting(to: UnitLength.meters).value, weight: UserPreferences.weight.value!).doubleValue
                }
                
                for tempEvent in object.events {
                    let event = transaction.create(Into<WorkoutEvent>())
                    event.uuid .= tempEvent.uuid ?? UUID()
                    event.eventType .= tempEvent.eventType
                    event.startDate .= tempEvent.startDate
                    event.endDate .= tempEvent.endDate
                }
                
                for location in object.locations {
                    let sample = transaction.create(Into<WorkoutRouteDataSample>())
                    sample.uuid .= location.uuid ?? UUID()
                    sample.latitude .= location.latitude
                    sample.longitude .= location.longitude
                    sample.altitude .= location.altitude
                    sample.timestamp .= location.timestamp
                    sample.horizontalAccuracy .= location.horizontalAccuracy
                    sample.verticalAccuracy .= location.verticalAccuracy
                    sample.speed .= location.speed
                    sample.direction .= location.direction
                    sample.workout .= workout
                }
                
                for heartRate in object.heartRates {
                    let sample = transaction.create(Into<WorkoutHeartRateDataSample>())
                    sample.uuid .= heartRate.uuid ?? UUID()
                    sample.heartRate .= heartRate.heartRate
                    sample.timestamp .= heartRate.timestamp
                }
                
                tempWorkouts.append(workout)
            }
            
            return tempWorkouts
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let tempWorkouts):
                    let workouts = dataStack.fetchExisting(tempWorkouts)
                    completion(true, nil, workouts)
                case .failure(let error):
                    completion(false, error, [])
                }
            }
        }
        
    }
    
    /// Imports multiple workouts into the database, typically used for importing a backup
    static func saveWorkouts(tempWorkouts: [TempWorkout], completion: @escaping ((Bool, Error?, [Workout]) -> Void), progressClosure: @escaping (Double) -> Void) {
        
        var workoutsToAddToAppleHealth = [Workout]()
        
        dataStack.perform(asynchronous: { (transaction) -> [Workout] in
            
            var returnWorkouts = [Workout]()
            
            progressClosure(0)
            
            for (index,tempWorkout) in tempWorkouts.enumerated() {
                
                let workout = transaction.create(Into<Workout>())
                workout.uuid .= tempWorkout.uuid ?? UUID()
                workout.workoutType .= tempWorkout.workoutType
                workout.startDate .= tempWorkout.startDate
                workout.endDate .= tempWorkout.endDate
                workout.distance .= tempWorkout.distance
                workout.steps .= tempWorkout.steps
                workout.isRace .= tempWorkout.isRace
                workout.isUserModified .= tempWorkout.isUserModified
                workout.comment .= tempWorkout.comment
                workout.burnedEnergy .= tempWorkout.burnedEnergy
                
                if let healthUUID = tempWorkout.healthKitUUID, HealthStoreManager.lookupExistence(of: healthUUID) {
                    workout.healthKitUUID .= healthUUID
                } else if UserPreferences.synchronizeWorkoutsWithAppleHealth.value {
                    workoutsToAddToAppleHealth.append(workout)
                }
                
                for tempEvent in tempWorkout.workoutEvents {
                    let event = transaction.create(Into<WorkoutEvent>())
                    event.uuid .= tempEvent.uuid ?? UUID()
                    event.eventType .= tempEvent.eventType
                    event.startDate .= tempEvent.startDate
                    event.endDate .= tempEvent.endDate
                    event.workout .= workout
                }
                
                for tempSample in tempWorkout.locations {
                    let sample = transaction.create(Into<WorkoutRouteDataSample>())
                    sample.uuid .= tempSample.uuid ?? UUID()
                    sample.latitude .= tempSample.latitude
                    sample.longitude .= tempSample.longitude
                    sample.altitude .= tempSample.altitude
                    sample.timestamp .= tempSample.timestamp
                    sample.horizontalAccuracy .= tempSample.horizontalAccuracy
                    sample.verticalAccuracy .= tempSample.verticalAccuracy
                    sample.speed .= tempSample.speed
                    sample.direction .= tempSample.direction
                    sample.workout .= workout
                }
                
                for heartRate in tempWorkout.heartRates {
                    let sample = transaction.create(Into<WorkoutHeartRateDataSample>())
                    sample.uuid .= heartRate.uuid ?? UUID()
                    sample.heartRate .= heartRate.heartRate
                    sample.timestamp .= heartRate.timestamp
                    sample.workout .= workout
                }
                
                progressClosure((Double(index) / Double(tempWorkouts.count)) / (UserPreferences.synchronizeWorkoutsWithAppleHealth.value ? 2 : 1))
                
                returnWorkouts.append(workout)
            }
            
            return returnWorkouts
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let tempWorkouts):
                    let workouts = dataStack.fetchExisting(tempWorkouts)
                    
                    if UserPreferences.synchronizeWorkoutsWithAppleHealth.value {
                    
                        let addWorkouts = dataStack.fetchExisting(workoutsToAddToAppleHealth)
                        addWorkouts.enumerated().forEach { (index, workout) in
                            
                            HealthStoreManager.saveHealthWorkout(
                                forWorkout: workout,
                                completion: { (success, hkWorkout) in
                                
                                    if !success {
                                        print("Error - Failed to add one imported Workout to Apple Health")
                                    }
                                    if index == addWorkouts.count - 1 {
                                        completion(true, nil, workouts)
                                    }
                                }
                            )
                        }
                        if addWorkouts.count == 0 {
                            progressClosure(1)
                            completion(true, nil, workouts)
                        }
                        
                    } else {
                        completion(true, nil, workouts)
                        progressClosure(1)
                    }
                case .failure(let error):
                    completion(false, error, [])
                }
            }
        }
    }
    
    /// Saves a single `TempWorkout` to the database and adds it to Apple Health if not already added
    static func saveWorkout(tempWorkout: TempWorkout, completion: @escaping ((Bool, Error?, Workout?) -> Void)) {
        
        var shouldAddWorkoutToAppleHealth = false
        
        saveWorkout(
            withType: tempWorkout.realWorkoutType,
            start: tempWorkout.startDate,
            end: tempWorkout.endDate,
            distance: tempWorkout.distance,
            steps: tempWorkout.steps,
            isRace: tempWorkout.isRace,
            isUserModified: tempWorkout.isUserModified,
            comment: tempWorkout.comment,
            burnedEnergy: tempWorkout.burnedEnergy,
            healthKitUUID: {
                if let uuid = tempWorkout.healthKitUUID {
                    return HealthStoreManager.lookupExistence(of: uuid) ? uuid : nil
                } else if UserPreferences.synchronizeWorkoutsWithAppleHealth.value {
                    shouldAddWorkoutToAppleHealth = true
                }
                return nil
            }(),
            events: tempWorkout.workoutEvents,
            routeSamples: tempWorkout.locations,
            heartRates: tempWorkout.heartRates,
            completion: { (databaseSuccess, error, workout) in
                if let workout = workout, shouldAddWorkoutToAppleHealth {
                    HealthStoreManager.saveHealthWorkout(forWorkout: workout, completion: { (success, hkWorkout) in
                        if !success {
                            print("Error - Failed to add TempWorkout to Apple Health")
                        }
                        completion(databaseSuccess, error, workout)
                    })
                } else {
                    completion(databaseSuccess, error, workout)
                }
            }
        )
    }
    
    // MARK: Alter Workout
    static func alterWorkout(workout: Workout, type: Workout.WorkoutType? = nil, start startDate: Date? = nil, end endDate: Date? = nil, distance: Double? = nil, steps: (Bool, Int?) /*= (false, nil)*/, isRace: Bool? = nil, comment: (Bool, String?) = (false, nil), weightBeforeWorkout: Double? = nil, completion: @escaping ((Bool, Error?, Workout?) -> Void)) {
        
        dataStack.perform(asynchronous: { (transaction) -> Workout in
            
            let workout = transaction.edit(workout)!
            
            if let type = type {
                workout.workoutType .= type.rawValue
            }
            if let startDate = startDate {
                workout.startDate .= startDate
                workout.dayIdentifier .= CustomTimeFormatting.dayIdentifier(forDate: startDate)
            }
            if let endDate = endDate {
                workout.endDate .= endDate
            }
            if let distance = distance {
                workout.distance .= distance
            }
            if steps.0 {
                workout.steps .= steps.1
            }
            if let isRace = isRace {
                workout.isRace .= isRace
            }
            if comment.0 {
                workout.comment .= comment.1
            }
            
            if startDate != nil || endDate != nil || distance != nil || steps.0 {
                workout.isUserModified .= true
            }

            guard let weightBeforeWorkout = weightBeforeWorkout else { return workout }

            if UserPreferences.weight.value != nil {
                workout.burnedEnergy .= BurnedEnergyCalculator.calculateBurnedCalories(for: workout.type, distance: workout.distance.value, weight: weightBeforeWorkout).doubleValue
            }
            
            return workout
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let workout):
                    guard let workout = dataStack.fetchExisting(workout) else {
                        completion(false, nil, nil)
                        return
                    }
                    workout.cachedStats = nil
                    completion(true, nil, workout)
                case .failure(let error):
                    completion(false, error, nil)
                    print("Failed to alter workout", error)
                }
            }
        }
        
    }
    
    // MARK: Save Event
    static func saveEvent(_ tempEvent: TempEvent, completion: @escaping (Bool, Error?, Event?) -> Void) {
        
        saveEvents(
            [tempEvent],
            completion: { (success, error, events) in
                completion(success, error, events.first)
            }
        )
        
    }
    
    static func saveEvents(_ tempEvents: [TempEvent], completion: @escaping (Bool, Error?, [Event]) -> Void) {
        
        dataStack.perform(asynchronous: { (transaction) -> [Event] in
            
            var returnEvents = [Event]()
            
            for tempEvent in tempEvents {
                let event = transaction.create(Into<Event>())
                
                event.uuid .= tempEvent.uuid ?? UUID()
                event.title .= tempEvent.title
                event.comment .= tempEvent.comment
                
                for uuid in tempEvent.workouts {
                    guard let workout = try transaction.fetchOne(From<Workout>().where(\.uuid == uuid)) else {
                        continue
                    }
                    event.workouts.value.insert(workout)
                }
                
                returnEvents.append(event)
            }
            
            return returnEvents
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let events):
                    let events = dataStack.fetchExisting(events)
                    completion(true, nil, events)
                case .failure(let error):
                    completion(false, error, [])
                    print("[DataManager] Failed to add events:", error)
                }
            }
        }
    }
    
    // MARK: Insert Backup Data
    static func insertUniqueBackupData(tempEvents: [TempEvent], tempWorkouts: [TempWorkout], completion: @escaping ((Bool, Error?, [Workout], [Event]) -> Void), progressClosure: @escaping (Double) -> Void) {
        
        DispatchQueue.main.async {
            do {
                let workoutUUIDDicts = try dataStack.queryAttributes(
                    From<Workout>()
                        .select(NSDictionary.self, .attribute(\.uuid))
                        .where(\.uuid != nil)
                )
                
                let existingUUIDs = workoutUUIDDicts.compactMap { (dict) -> UUID? in
                    guard let id = UUID(uuidString: dict.first?.value as? String ?? "") else {
                        print("Unexpectedly found workout uuid nil while mapping")
                        return nil
                    }
                    return id
                }
                
                let importWorkouts = tempWorkouts.filter { (tempWorkout) -> Bool in
                    guard let uuid = tempWorkout.uuid else {
                        return false
                    }
                    return !existingUUIDs.contains(uuid)
                }
                saveWorkouts(tempWorkouts: importWorkouts, completion: { (workoutSuccess, workoutError, workouts) in
                    DispatchQueue.main.async {
                        do {
                            let eventUUIDDicts = try dataStack.queryAttributes(
                                From<Event>()
                                    .select(NSDictionary.self, .attribute(\.uuid))
                                    .where(\.uuid != nil)
                            )
                            
                            let existingEventUUIDs = eventUUIDDicts.compactMap { (dict) -> UUID? in
                                guard let id = UUID(uuidString: dict.first?.value as? String ?? "") else {
                                    print("Unexpectedly found event uuid nil while mapping")
                                    return nil
                                }
                                return id
                            }
                            
                            let importEvents = tempEvents.filter { (tempEvent) -> Bool in
                                guard let uuid = tempEvent.uuid else {
                                    return false
                                }
                                return !existingEventUUIDs.contains(uuid)
                            }
                            
                            DataManager.saveEvents(importEvents) { (eventSuccess, eventError, events) in
                                completion(workoutSuccess && eventSuccess, workoutError ?? eventError ?? nil, workouts, events)
                            }
                        } catch {
                            completion(workoutSuccess, error, workouts, [])
                        }
                    }
                }, progressClosure: progressClosure)
                
            } catch {
                completion(false, error, [], [])
            }
        }
    }
    
    // MARK: HealthKit Reference
    static func addHealthKitWorkoutUUID(forWorkout workout: Workout, uuid: UUID, completion: @escaping (Bool) -> Void) {
        var editFailed = false
        dataStack.perform(asynchronous: { (transaction) -> Workout in
            guard let wo = transaction.edit(workout) else {
                print("Failed to edit Workout:", workout)
                editFailed = true
                return workout
            }
            wo.healthKitUUID .= uuid
            return wo
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    completion(!editFailed)
                case .failure(let error):
                    print("Failed to save Workout after trying to insert Health Kit uuid into Workout:", error)
                    completion(false)
                }
            }
        }
    }
    
    static func removeHealthKitWorkoutUUID(forWorkout workout: Workout, completion: @escaping (Bool) -> Void) {
        var editFailed = false
        dataStack.perform(asynchronous: { (transaction) -> Workout in
            guard let wo = transaction.edit(workout) else {
                print("Failed to edit Workout:", workout)
                editFailed = true
                return workout
            }
            wo.healthKitUUID .= nil
            return wo
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    completion(!editFailed)
                case .failure(let error):
                    completion(false)
                    print("Failed to save Workout after trying to remove Health Workout reference:", error.debugDescription)
                }
            }
        }
    }
    
    static func removeAllHealthKitWorkoutUUIDs(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            do {
                let workouts = try dataStack.fetchAll(From<Workout>())
                
                var removalFailed = false
                
                for workout in workouts where workout.healthKitUUID.value != nil {
                    DataManager.removeHealthKitWorkoutUUID(forWorkout: workout) { (success) in
                        if !success {
                            removalFailed = true
                        }
                    }
                }
                
                completion(!removalFailed)
            } catch {
                completion(false)
                print("Failed to fetch workouts for removing reference to HealthKit Workout")
            }
        }
    }
    
    static func removeHealthKitReference(for uuid: UUID, completion: @escaping (Bool) -> Void) {
        dataStack.perform(asynchronous: { (transaction) -> [Workout] in
            
            do {
                let workouts = try transaction.fetchAll(From<Workout>().where(\.healthKitUUID == uuid))
                for workout in workouts {
                    workout.healthKitUUID .= nil
                }
                return workouts
            } catch {
                return []
            }
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    completion(true)
                case .failure(let error):
                    completion(false)
                    print("Failed to delete workout in database:", error.debugDescription)
                }
            }
        }
    }
    
    // MARK: Delete Workout
    static func delete(workout: Workout, completion: @escaping (Bool) -> Void) {
        dataStack.perform(asynchronous: { (transaction) -> Void in
            transaction.delete(workout)
            do {
                try transaction.deleteAll(From<WorkoutRouteDataSample>().where(\.workout == workout))
            } catch {
                print("Could not delete route data of workout")
            }
            return
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    completion(true)
                case .failure(let error):
                    completion(false)
                    print("Failed to delete workout in database:", error.debugDescription)
                }
            }
        }
    }
    
    static func deleteAll(completion: @escaping (Bool) -> Void) {
        dataStack.perform(asynchronous: { (transaction) -> Void in
            do {
                try transaction.deleteAll(From<Workout>())
                try transaction.deleteAll(From<WorkoutRouteDataSample>())
            } catch {
                print("Could not delete all route data and workouts")
            }
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    completion(true)
                case .failure(let error):
                    completion(false)
                    print("Failed to delete all objects in database:", error.debugDescription)
                }
            }
        }
    }
    
    // MARK: Workout Monitor
    static let workoutMonitor = dataStack.monitorList(
        From<Workout>()
            .orderBy(.descending(\.startDate))
            .where(Where<Workout>(true))
    )
    
}
