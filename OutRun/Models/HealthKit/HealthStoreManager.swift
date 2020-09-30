//
//  HealthStoreManager.swift
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

import HealthKit
import CoreLocation

enum HealthStoreManager {
    
    static let healthStore = HKHealthStore()
    
    static let objectTypeWorkoutType = HKObjectType.workoutType()
    static let objectTypeActiveEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    static let objectTypeDistanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
    static let objectTypeDistanceCycling = HKObjectType.quantityType(forIdentifier: .distanceCycling)!
    static let objectTypeRouteType = HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
    static let objectTypeBodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    static let objectTypeHeartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
    static let objectTypeStepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    
    static let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
    
    static let requestedTypes = Set([
        objectTypeWorkoutType,
        objectTypeActiveEnergyBurned,
        objectTypeDistanceWalkingRunning,
        objectTypeDistanceCycling,
        objectTypeRouteType,
        objectTypeBodyMass,
        objectTypeHeartRate,
        objectTypeStepCount
    ])
    
    static func gainAuthorization(completion: @escaping (Bool) -> Void) {
        
        HealthStoreManager.healthStore.requestAuthorization(toShare: requestedTypes, read: requestedTypes) { (success, error) in
            
            if !success {
                
                guard let error = error else {
                    print("[Health] Unknown error for health store authorization")
                    return
                }
                print("[Health] Error for health store authorization:", error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                completion(success)
            }
            
        }
    }
    
    static func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return HealthStoreManager.healthStore.authorizationStatus(for: type)
    }
    
    // MARK: Save Health Workout
    static func saveHealthWorkout(forWorkout workout: Workout, completion: @escaping (Bool, HKWorkout?) -> Void) {
        
        let safeCompletion: (Bool, HKWorkout?) -> Void = { (success, hkWorkout) in
            DispatchQueue.main.async {
                completion(success, hkWorkout)
            }
        }
        
        DispatchQueue.main.async {
            let tempWorkout = TempWorkout(workout: workout)
            
            HealthStoreManager.gainAuthorization { (success) in
                
                if success {
                    
                    let startDate = tempWorkout.startDate
                    let endDate = tempWorkout.endDate
                    
                    let distanceQuantity = HKQuantity(
                        unit: .meter(),
                        doubleValue: tempWorkout.distance)
                    let stepsQuantity = tempWorkout.steps != nil ? HKQuantity(unit: .count(), doubleValue: Double(tempWorkout.steps!)) : nil
                    let burnedCalories = tempWorkout.burnedEnergy != nil ? tempWorkout.burnedEnergy! : nil
                    let caloriesQuantity = burnedCalories != nil ? HKQuantity(unit: .kilocalorie(), doubleValue: burnedCalories!) : nil
                    
                    let workoutEvents = tempWorkout.workoutEvents.compactMap { (event) -> HKWorkoutEvent? in
                        guard let type = event.realEventType.healthKitType else {
                            return nil
                        }
                        return HKWorkoutEvent(type: type, dateInterval: DateInterval(start: event.startDate, duration: 0), metadata: nil)
                    }
                    
                    let healthWorkout = HKWorkout(
                        activityType: tempWorkout.realWorkoutType.healthKitType,
                        start: startDate,
                        end: endDate,
                        workoutEvents: workoutEvents,
                        totalEnergyBurned: caloriesQuantity,
                        totalDistance: distanceQuantity,
                        device: HKDevice.local(),
                        metadata: [
                            HKMetadataKeyWasUserEntered : tempWorkout.isUserModified
                        ]
                    )
                    
                    var samplesToAdd = [HKSample]()
                    if tempWorkout.realWorkoutType == .cycling {
                        if authorizationStatus(for: objectTypeDistanceCycling) == HKAuthorizationStatus.sharingAuthorized {
                            let distanceSample = HKQuantitySample(
                                type: objectTypeDistanceCycling,
                                quantity: distanceQuantity,
                                start: startDate,
                                end: endDate,
                                device: HKDevice.local(),
                                metadata: nil
                            )
                            samplesToAdd.append(distanceSample)
                        }
                    }
                    
                    if [.running, .walking].contains(tempWorkout.realWorkoutType) {
                        if authorizationStatus(for: objectTypeDistanceWalkingRunning) == HKAuthorizationStatus.sharingAuthorized {
                            let distanceSample = HKQuantitySample(
                                type: objectTypeDistanceWalkingRunning,
                                quantity: distanceQuantity,
                                start: startDate,
                                end: endDate,
                                device: HKDevice.local(),
                                metadata: nil
                            )
                            samplesToAdd.append(distanceSample)
                        }
                    }
                    
                    if authorizationStatus(for: objectTypeStepCount) == HKAuthorizationStatus.sharingAuthorized {
                        if let stepsQuantity = stepsQuantity {
                            let stepsSample = HKQuantitySample(
                                type: objectTypeStepCount,
                                quantity: stepsQuantity,
                                start: startDate,
                                end: endDate,
                                device: HKDevice.local(),
                                metadata: nil
                            )
                            samplesToAdd.append(stepsSample)
                        }
                    }
                    
                    if authorizationStatus(for: objectTypeActiveEnergyBurned) == HKAuthorizationStatus.sharingAuthorized {
                        if let caloriesQuantity = caloriesQuantity {
                            let caloriesSample = HKQuantitySample(
                                type: objectTypeActiveEnergyBurned,
                                quantity: caloriesQuantity,
                                start: startDate as Date,
                                end: endDate as Date,
                                device: HKDevice.local(),
                                metadata: nil
                            )
                            samplesToAdd.append(caloriesSample)
                        }
                    }
                    
                    HealthStoreManager.healthStore.save(healthWorkout) { (workoutSuccess, error) in
                        
                        if workoutSuccess {
                            
                            HealthStoreManager.attachRoute(to: healthWorkout, with: tempWorkout)
                            
                            // not fully implemented yet
                            /*
                            HealthStoreManager.attachHeartRates(to: healthWorkout, with: tempWorkout)
                            */
                            
                            HealthStoreManager.healthStore.add(samplesToAdd, to: healthWorkout, completion: { (sampleSuccess, error) in
                                if !sampleSuccess {
                                    print("[Health] Error - Failed to add samples to Health Workout")
                                }
                            })
                            
                            DataManager.addHealthKitWorkoutUUID(forWorkout: workout, uuid: healthWorkout.uuid) { (success) in
                                safeCompletion(success, healthWorkout)
                                if !success {
                                    print("[Health] Error - Saved workout to Health Store but failed to add reference to database")
                                }
                            }
                            
                        } else {
                            safeCompletion(false, nil)
                            print("[Health] Error - Failed to save workout")
                        }
                    }
                    
                } else {
                    
                    safeCompletion(false, nil)
                    
                }
                
            }
        }
    }
    
    // MARK: Attatch Route To Health Workout
    static func attachRoute(to hkWorkout: HKWorkout, with workout: TempWorkout) {
        
        let locations = workout.locations.compactMap { (sample) -> CLLocation? in
            return sample.clLocation
        }
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: HealthStoreManager.healthStore, device: nil)
        routeBuilder.insertRouteData(locations) { (success, error) in
            if !success {
                print("[Health] Error - failed to create route for Health Workout")
            } else {
                routeBuilder.finishRoute(with: hkWorkout, metadata: nil) { (route, error) in
                    if route == nil {
                        print("[Health] Error - failed to finish route for Health Workout:")
                    }
                }
            }
        }
        
    }
    
    // MARK: Attatch Heart Rates To Health Workout
    static func attachHeartRates(to hkWorkout: HKWorkout, with workout: TempWorkout) {
        
        func add(_ samples: [HKSample]) {
            HealthStoreManager.healthStore.add(samples, to: hkWorkout) { (success, error) in
                if !success {
                    print("[Health] Failed to add heart rates to health workout")
                }
            }
        }
        
        if #available(iOS 12.0, *) {
            let heartRateBuilder = HKQuantitySeriesSampleBuilder(healthStore: HealthStoreManager.healthStore, quantityType: objectTypeHeartRate, startDate: workout.startDate, device: nil)
            for (index, heartRateSample) in workout.heartRates.enumerated() {
                
                do {
                    try heartRateBuilder.insert(HKQuantity(unit: HealthStoreManager.heartRateUnit, doubleValue: heartRateSample.heartRate), at: heartRateSample.timestamp)
                } catch {
                    print("[Health] Failed to create heart rate series for apple health")
                    break
                }
                
                if index + 1 == workout.heartRates.count {
                    heartRateBuilder.finishSeries(metadata: nil, endDate: workout.endDate) { (seriesSample, error) in
                        if let seriesSample = seriesSample {
                            add(seriesSample)
                        } else {
                            print("[Health] Failed to create heart rate series for apple health")
                        }
                    }
                }
            }
            
        } else {
            let heartRateSamples = workout.heartRates.map { heartRateSample -> HKQuantitySample in
                return HKQuantitySample(type: objectTypeHeartRate, quantity: HKQuantity(unit: HealthStoreManager.heartRateUnit, doubleValue: Double(heartRateSample.heartRate)), start: heartRateSample.timestamp, end: heartRateSample.timestamp)
            }
            add(heartRateSamples)
        }
    }
    
    // MARK: Delete Health Workout
    static func deleteHealthWorkout(fromWorkout workout: Workout, completion: @escaping (Bool) -> Void) {
        
        let safeCompletion: (Bool) -> Void = { success in
            DispatchQueue.main.async {
                completion(success)
            }
        }
        
        DispatchQueue.main.async {
            guard let targetUUID = workout.healthKitUUID.value else {
                safeCompletion(false)
                return
            }
            
            HealthStoreManager.gainAuthorization { (success) in
                
                if success {
                    
                    let predicate = HKQuery.predicateForObject(with: targetUUID)
                    
                    let query = HKSampleQuery(sampleType: objectTypeWorkoutType, predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
                        
                        guard let hkWorkout = samples?.first as? HKWorkout else {
                            safeCompletion(false)
                            return
                        }
                        
                        let workoutPredicate = HKQuery.predicateForObjects(from: hkWorkout)
                        
                        var deleteCount = 0
                        var deleteSuccess = true
                        
                        func deleteRelatedObjects(of type: HKObjectType) {
                            HealthStoreManager.healthStore.deleteObjects(of: type, predicate: workoutPredicate) { (success, deletedObjects, error) in
                                
                                print("[Health] deleted \(deletedObjects) objects of type '\(type.debugDescription)'")
                                
                                if let error = error {
                                    print("[Health] Error - failed to delete workout related sample of type '\(type.debugDescription)':", error.localizedDescription)
                                }
                                
                                if !success {
                                    deleteSuccess = false
                                }
                                deleteCount += 1
                                
                                if deleteCount == 3 {
                                    if deleteSuccess {
                                        HealthStoreManager.healthStore.delete(hkWorkout) { (workoutDeleteSuccess, error) in
                                            if workoutDeleteSuccess {
                                                DispatchQueue.main.async {
                                                    DataManager.removeHealthKitWorkoutUUID(forWorkout: workout) { (removalSuccess) in
                                                        safeCompletion(removalSuccess)
                                                    }
                                                }
                                            } else {
                                                safeCompletion(workoutDeleteSuccess)
                                            }
                                            
                                            if let error = error {
                                                print("[Health] Error - failed to delete workout:", error.localizedDescription)
                                            }
                                        }
                                    } else {
                                        safeCompletion(false)
                                    }
                                }
                                
                            }
                        }
                        
                        DispatchQueue.main.async {
                            if [.running, .walking, .cycling].contains(workout.type) {
                                deleteRelatedObjects(of: workout.type == .cycling ? objectTypeDistanceCycling : objectTypeDistanceWalkingRunning)
                            }
                            deleteRelatedObjects(of: objectTypeRouteType)
                            deleteRelatedObjects(of: objectTypeActiveEnergyBurned)
                            // MARK: not implemented
                            // deleteRelatedObjects(of: objectTypeHeartRate)
                            deleteRelatedObjects(of: objectTypeStepCount)
                        }
                        
                    }
                    
                    HealthStoreManager.healthStore.execute(query)
                    
                } else {
                    
                    safeCompletion(false)
                    
                }
            }
        }
    }
    
    // MARK: Alter Health Workout
    static func alterHealthWorkout(from workout: Workout, completion: @escaping (Bool) -> Void) {
        
        let safeCompletion: (Bool) -> Void = { success in
            DispatchQueue.main.async {
                completion(success)
            }
        }
        
        HealthStoreManager.gainAuthorization { (success) in
            
            if success {
                HealthStoreManager.deleteHealthWorkout(fromWorkout: workout) { (deleteSuccess) in
                    
                    if deleteSuccess {
                        HealthStoreManager.saveHealthWorkout(forWorkout: workout) { (saveSuccess, hkWorkout) in
                            safeCompletion(saveSuccess)
                            print("[Health] Error - Failed to resave workout in order to alter it")
                        }
                    } else {
                        safeCompletion(false)
                        print("[Health] Error - Failed to delete workout in order to alter it")
                    }
                }
                
            } else {
                safeCompletion(false)
            }
            
        }
        
    }
    
    // MARK: Delete All Health Workouts
    static func deleteAllHealthWorkouts(completion: @escaping (Bool) -> Void) {
        
        let safeCompletion: (Bool) -> Void = { success in
            DispatchQueue.main.async {
                completion(success)
            }
        }
        
        HealthStoreManager.gainAuthorization { (success) in
            
            if success {
                
                let predicate = HKQuery.predicateForObjects(from: HKSource.default())
                
                var deleteCount = 0
                var deleteSuccess = true
                
                func deleteAll(for type: HKObjectType) {
                    HealthStoreManager.healthStore.deleteObjects(of: type, predicate: predicate) { (success, numberOfDeletedObjects, error) in
                        
                        print("[Health] deleted \(numberOfDeletedObjects) objects of type '\(type.debugDescription)'")
                        
                        if !success {
                            deleteSuccess = false
                        }
                        
                        deleteCount += 1
                        
                        if deleteCount == requestedTypes.count {
                            DataManager.removeAllHealthKitWorkoutUUIDs { (removalSuccess) in
                                safeCompletion(removalSuccess && deleteSuccess)
                            }
                        }
                    }
                }
                
                requestedTypes.forEach { (type) in
                    deleteAll(for: type)
                }
                
            } else {
                
                safeCompletion(false)
                
            }
            
        }
        
    }
    
    // MARK: Save New Weight
    static func syncWeight(measurement: NSMeasurement, completion: @escaping (Bool) -> Void) {
        
        let safeCompletion: (Bool) -> Void = { success in
            DispatchQueue.main.async {
                completion(success)
            }
        }
        
        HealthStoreManager.gainAuthorization { (success) in
            
            guard success, measurement.canBeConverted(to: UnitMass.kilograms) else {
                completion(false)
                return
            }
            
            let weightValue = measurement.converting(to: UnitMass.kilograms).value
            let quantity = HKQuantity(unit: HKUnit.init(from: .kilogram), doubleValue: weightValue)
            let sample = HKQuantitySample(
                type: objectTypeBodyMass,
                quantity: quantity,
                start: Date(),
                end: Date(),
                metadata: [
                    HKMetadataKeyWasUserEntered : true
                ]
            )
            
            HealthStoreManager.healthStore.save(sample) { (success, error) in
                safeCompletion(success)
            }
            
        }
        
    }
    
    // MARK: Sync All Unsycned Workouts With Apple Health
    /// Function to sync all unsynced workouts with the health store, completion returning the success state and the state if all workouts have been synced already
    static func syncAllUnsyncedWorkoutsWithAppleHealth(completion: @escaping (Bool, Bool?) -> Void) {
        
        let safeCompletion: (Bool, Bool?) -> Void = { (success, allSyncedAlready) in
            DispatchQueue.main.async {
                completion(success, allSyncedAlready)
            }
        }
        
        HealthStoreManager.gainAuthorization { (authSuccess) in
            
            if authSuccess {
                
                DataQueryManager.queryAllWorkoutsWithoutAppleHealthReference { (querySuccess, workouts) in
                    
                    if querySuccess {
                        
                        var saveCount = 0
                        var saveSuccess = true
                        
                        workouts.enumerated().forEach { (index, workout) in
                            HealthStoreManager.saveHealthWorkout(forWorkout: workout) { (success, hkWorkout) in
                                if !success {
                                    saveSuccess = false
                                }
                                
                                saveCount += 1
                                
                                if saveCount == workouts.count {
                                    safeCompletion(saveSuccess, false)
                                }
                            }
                        }
                        
                        if workouts.count == 0 {
                            safeCompletion(true, true)
                        }
                        
                    } else {
                        safeCompletion(false, nil)
                    }
                }
            } else {
                safeCompletion(false, nil)
            }
        }
    }
    
    // MARK: Check if workout exists
    static func lookupExistence(of uuid: UUID) -> Bool {
        
        var uuidExists = false
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        let query = HKSampleQuery(sampleType: HealthStoreManager.objectTypeWorkoutType, predicate: HKQuery.predicateForObject(with: uuid), limit: 1, sortDescriptors: nil) { (query, samples, error) in
            uuidExists = !(samples?.isEmpty ?? true)
            dispatchGroup.leave()
        }
        
        HealthStoreManager.healthStore.execute(query)
        dispatchGroup.wait()
        
        return uuidExists
    }
    
}
