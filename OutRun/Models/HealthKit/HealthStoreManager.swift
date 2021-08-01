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

class HealthStoreManager {
    
    /// A reference to the `HKHealthStore`, the central database and API of HealthKit.
    private static let healthStore = HKHealthStore()
    
    // MARK: - Constants
    
    /// A class containing static instances of `HKSampleType` for reference to HealthKit objects.
    public class HealthType {
        
        static let Workout = HKObjectType.workoutType()
        static let ActiveEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        static let DistanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        static let DistanceCycling = HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        static let Route = HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
        static let BodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        static let HeartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
        static let StepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        /// A static constant containing all HealthKit types implemented and thereby usable in OutRun.
        static let allImplementedTypes: [HKObjectType] = [
            HealthType.Workout,
            HealthType.ActiveEnergyBurned,
            HealthType.DistanceWalkingRunning,
            HealthType.DistanceCycling,
            HealthType.Route,
            HealthType.BodyMass,
            HealthType.HeartRate,
            HealthType.StepCount
        ]
        
    }
    
    /// A class containing static instances of special `HKUnit` objects.
    public class HealthUnit {
        
        static let HeartRate = HealthKit.HKUnit.count().unitDivided(by: HealthKit.HKUnit.minute())
        
    }
    
    // MARK: - Authorisation
    
    /**
     A function to request authorisation to read and write specified types from the health store.
     - parameter requestedTypes: the types authorisation is supposed to be requested for
     - parameter completion: a closure being performed on completion of the operation and indicating it's success
     */
    static func gainAuthorisation(for requestedTypes: HKSampleType..., completion: @escaping (Bool) -> Void) {
        
        let requestedTypes = Set(requestedTypes)
        HealthStoreManager.healthStore.requestAuthorization(toShare: requestedTypes, read: requestedTypes) { (success, error) in
            
            
            if !success {
                
                guard let error = error else {
                    print("[Health] Unknown error for health store authorisation")
                    return
                }
                print("[Health] Error for health store authorisation:", error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                completion(success)
            }
            
        }
    }
    
    /**
     A function to provide the current authorisation status of an HealthKit object type.
     - parameter type: the type that is supposed to be checked
     - returns: the authorisation status of the provided type
     */
    static func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return HealthStoreManager.healthStore.authorizationStatus(for: type)
    }
    
    /**
     Checks the authorisation status for a HKObjektType and adds it to an array if unauthorised.
     - parameter type: the type to be checked and added
     - parameter array: the array the type is suppused to be added to
     - parameter onAuthorised: the closure being performed if authorisation is granted
     */
    static func checkAuthorisation(for samples: HKQuantitySample?..., authArray: inout [HKQuantitySample], unauthArray: inout [HKObjectType]) {
        
        for sample in samples {
            guard let sample = sample else { return }
            if authorizationStatus(for: sample.quantityType) == .sharingAuthorized {
                authArray.append(sample)
            } else {
                unauthArray.append(sample.quantityType)
            }
        }
    }
    
    // MARK: - HKHealthStore Manipulation
    
    /**
     Saves the provided workout to the healthStore.
     - parameter workout: the workout that is supposed to be saved
     - parameter completion: the closure performed upon completion of saving
     */
    static func saveHealthWorkout(for workout: ORWorkoutInterface, completion: @escaping (HealthError?, HKWorkout?) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        gainAuthorisation(for: HealthType.Workout) { workoutAuthorisation in
            
            guard workoutAuthorisation else {
                completion(.insufficientAuthorisation, nil)
                return
            }
            
            let (start, end) = (workout.startDate, workout.endDate)
            let distance = createHealthQuantity(value: workout.distance, unit: .meter())
            let calories = createHealthQuantity(value: workout.burnedEnergy, unit: .kilocalorie())
            
            let workoutEvents = createWorkoutEvents(from: workout)
            
            let healthWorkout = HKWorkout(
                activityType: workout.workoutType.healthKitType,
                start: start,
                end: end,
                workoutEvents: workoutEvents,
                totalEnergyBurned: calories,
                totalDistance: distance,
                device: HKDevice.local(),
                metadata: [
                    HKMetadataKeyWasUserEntered : workout.isUserModified
                ]
            )
            
            var missingAuth = [HKObjectType]()
            var samples = [HKQuantitySample]()
            
            let distanceSample = createHealthQuantitySample(
                of: workout.workoutType.healthKitDistanceType,
                quantity: distance,
                associatedWorkout: healthWorkout
            )
            let caloriesSample = createHealthQuantitySample(
                of: HealthType.ActiveEnergyBurned,
                quantity: calories,
                associatedWorkout: healthWorkout
            )
            let stepsSample = createHealthQuantitySample(
                of: HealthType.StepCount,
                quantityValue: Double(workout.steps),
                quantityUnit: .count(),
                associatedWorkout: healthWorkout
            )
            
            checkAuthorisation(
                for: distanceSample, caloriesSample, stepsSample,
                authArray: &samples,
                unauthArray: &missingAuth
            )
            
            
            
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
                        if authorizationStatus(for: HealthType.DistanceCycling) == HKAuthorizationStatus.sharingAuthorized {
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
                        if authorizationStatus(for: HealthType.DistanceWalkingRunning) == HKAuthorizationStatus.sharingAuthorized {
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
                    
                    if authorizationStatus(for: HealthType.StepCount) == HKAuthorizationStatus.sharingAuthorized {
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
                    
                    if authorizationStatus(for: HealthType.ActiveEnergyBurned) == HKAuthorizationStatus.sharingAuthorized {
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
    
    // MARK: - Object Creation
    
    /**
     Creates an `HKQuantity` object from the provided data if the value is not `nil`
     - parameter value: the value of the quantity; if `nil` this function will not return a value
     - parameter unit: the unit of the quantity
     - returns: an object of type `HKQuantity` if the provided data was valid
     */
    private static func createHealthQuantity(value: Double?, unit: HKUnit) -> HKQuantity? {
        
        guard let value = value else { return nil }
        
        return HKQuantity(
            unit: unit,
            doubleValue: value
        )
        
    }
    
    /**
     Creates an `HKQuantitySample` object from the provided data if the value is not `nil`.
     - parameter healthType: the type of the quantity sample
     - parameter quanitity: the quantity to be saved
     - parameter healthWorkout: the health workout this sample is supposed to be attached to
     - returns: an object of type `HKQuantitySample`
     */
    private static func createHealthQuantitySample(of healthType: HKQuantityType?, quantity: HKQuantity?, associatedWorkout healthWorkout: HKWorkout) -> HKQuantitySample? {
        
        guard let healthType = healthType, let quantity = quantity else { return nil }
        
        return HKQuantitySample(
            type: healthType,
            quantity: quantity,
            start: healthWorkout.startDate,
            end: healthWorkout.endDate,
            device: healthWorkout.device,
            metadata: healthWorkout.metadata
        )
    }
    
    /**
     Creates an `HKQuantitySample` object from the provided data if the value is not `nil`.
     - parameter healthType: the type of the quantity sample
     - parameter quanitityValue: the value to be saved in the quantity sample; if `nil` this function will not return a value
     - parameter quantityUnit: the unit of the quantity sample
     - parameter healthWorkout: the health workout this sample is supposed to be attached to
     - returns: an object of type `HKQuantitySample` if the provided data was valid
     */
    private static func createHealthQuantitySample(of healthType: HKQuantityType?, quantityValue: Double?, quantityUnit: HKUnit, associatedWorkout healthWorkout: HKWorkout) -> HKQuantitySample? {
        
        return createHealthQuantitySample(
            of: healthType,
            quantity: createHealthQuantity(
                value: quantityValue,
                unit: quantityUnit
            ),
            associatedWorkout: healthWorkout
        )
    }
    
    /**
     Creates `HKWorkoutEvent`s from the pause and workout event objects of a given workout
     - parameter workout: the workout object the pause and workout event objects are taken from
     - returns: the created array of `HKWorkoutEvent`
     */
    private static func createWorkoutEvents(from workout: ORWorkoutInterface) -> [HKWorkoutEvent] {
        
        var workoutEvents = [HKWorkoutEvent]()
        
        workout.pauses.forEach { pause in
            
            let events = [
                HKWorkoutEvent(
                    type: pause.pauseType == .manual ? .pause : .motionPaused,
                    dateInterval: DateInterval(start: pause.startDate, duration: 0),
                    metadata: nil
                ),
                workout.endDate == pause.endDate ? nil : HKWorkoutEvent(
                    type: pause.pauseType == .manual ? .resume : .motionResumed,
                    dateInterval: DateInterval(start: pause.endDate, duration: 0),
                    metadata: nil
                )
            ].compactMap { $0 }
            
            workoutEvents.append(contentsOf: events)
        }
        
        workout.workoutEvents.forEach { event in
            
            guard let type = event.eventType.healthKitType else { return }
            
            workoutEvents.append(
                HKWorkoutEvent(
                    type: type,
                    dateInterval: DateInterval(start: event.timestamp, duration: 0),
                    metadata: nil
                )
            )
        }
        
    }
    
    // MARK: - TODO - DEAL WITH LATER
    
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
            let heartRateBuilder = HKQuantitySeriesSampleBuilder(healthStore: HealthStoreManager.healthStore, quantityType: HealthType.HeartRate, startDate: workout.startDate, device: nil)
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
            guard let targetUUID = workout.healthKitUUID else {
                safeCompletion(false)
                return
            }
            
            HealthStoreManager.gainAuthorization { (success) in
                
                if success {
                    
                    let predicate = HKQuery.predicateForObject(with: targetUUID)
                    
                    let query = HKSampleQuery(sampleType: HealthType.Workout, predicate: predicate, limit: 1, sortDescriptors: nil) { (query, samples, error) in
                        
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
                            deleteRelatedObjects(of: HealthType.ActiveEnergyBurned)
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
                type: HealthType.BodyMass,
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
        
        let query = HKSampleQuery(sampleType: HealthStoreManager.HealthType.Workout, predicate: HKQuery.predicateForObject(with: uuid), limit: 1, sortDescriptors: nil) { (query, samples, error) in
            uuidExists = !(samples?.isEmpty ?? true)
            dispatchGroup.leave()
        }
        
        HealthStoreManager.healthStore.execute(query)
        dispatchGroup.wait()
        
        return uuidExists
    }
    
}
