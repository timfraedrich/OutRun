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
import CoreStore

class HealthStoreManager {
    
    /// A reference to the `HKHealthStore`, the central database and API of HealthKit.
    static let healthStore = HKHealthStore()
    
    // MARK: - Constants
    
    /// A class containing static instances of `HKSampleType` for reference to HealthKit objects.
    class HealthType {
        
        static let Workout = HKObjectType.workoutType()
        static let ActiveEnergyBurned = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        static let DistanceWalkingRunning = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        static let DistanceCycling = HKObjectType.quantityType(forIdentifier: .distanceCycling)!
        static let Route = HKObjectType.seriesType(forIdentifier: HKWorkoutRouteTypeIdentifier)!
        static let BodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass)!
        static let HeartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
        static let StepCount = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        /// A static constant containing all HealthKit types implemented and thereby usable in OutRun.
        static let allImplementedTypes: [HKSampleType] = [
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
    class HealthUnit {
        
        static let HeartRate = HKUnit.count().unitDivided(by: HealthKit.HKUnit.minute())
        static let Kilogram = HKUnit(from: .kilogram)
        
    }
    
    // MARK: - Authorisation
    
    /**
     A function to request authorisation to read and write specified types from the health store.
     - parameter requestedTypes: the types authorisation is supposed to be requested for
     - parameter completion: a closure being performed on completion of the operation and indicating it's success
     - parameter success: indicates whether full authorisation was granted
     - parameter authorisedTypes: provides the types which were authorised by the user
     */
    static func gainAuthorisation(for requestedTypes: [HKSampleType] = HealthType.allImplementedTypes, completion: @escaping (_ success: Bool, _ authorisedTypes: [HKSampleType]) -> Void) {
        let completion = safeClosure(from: completion)
        
        let types = Set(requestedTypes)
        HealthStoreManager.healthStore.requestAuthorization(toShare: types, read: types) { (success, error) in
            
            if let error = error {
                print("[Health] Error for health store authorisation:", error.localizedDescription)
            } else {
                print("[Health] Unknown error for health store authorisation")
            }
            
            let authorisedTypes = requestedTypes.filter { HealthStoreManager.healthStore.authorizationStatus(for: $0) == .sharingAuthorized }
            let success = authorisedTypes == requestedTypes
            
            completion(success, authorisedTypes)
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
    
    // MARK: - Saving
    
    /**
     Saves the provided workout to the healthStore.
     - parameter workout: the workout that is supposed to be saved
     - parameter completion: the closure performed upon the completion of saving
     */
    static func saveHealthWorkout(for workout: ORWorkoutInterface, completion: @escaping (HealthError?, HKWorkout?) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        gainAuthorisation(for: [HealthType.Workout]) { workoutAuthorisation, _ in
            
            guard workoutAuthorisation else { completion(.insufficientAuthorisation, nil); return }
            
            let (start, end) = (workout.startDate, workout.endDate)
            let distance = createHealthQuantity(value: workout.distance, unit: .meter())
            let calories = createHealthQuantity(value: workout.burnedEnergy, unit: .kilocalorie())
            
            let workoutEvents = createWorkoutEvents(from: workout)
            
            var metadata: [String : Any] = [HKMetadataKeyWasUserEntered : workout.isUserModified]
            if let uuid = workout.uuid { metadata[HKMetadataKeyExternalUUID] = uuid.uuidString }
            
            let healthWorkout = HKWorkout(
                activityType: workout.workoutType.healthKitType,
                start: start,
                end: end,
                workoutEvents: workoutEvents,
                totalEnergyBurned: calories,
                totalDistance: distance,
                device: HKDevice.local(),
                metadata: metadata
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
            
            let heartRateSamples = createHeartRateSamples(from: workout)
            if authorizationStatus(for: HealthType.HeartRate) == .sharingAuthorized {
                samples.append(contentsOf: heartRateSamples)
            } else {
                missingAuth.append(HealthType.HeartRate)
            }
            
            HealthStoreManager.healthStore.save(healthWorkout) { (workoutSuccess, error) in
                
                guard workoutSuccess else {
                    completion(.healthKitError(error: error), nil)
                    return
                }
                
                createWorkoutRoute(from: workout, andAttachTo: healthWorkout)
                
                HealthStoreManager.healthStore.add(samples, to: healthWorkout) { (success, error) in
                    guard let error = error else { return }
                    print("[Health] Error - Failed to add samples to Health workout:", error.localizedDescription)
                }
                
                DataManager.editHealthReference(for: workout, reference: healthWorkout.uuid)
                
                completion(missingAuth.isEmpty ? nil : .optionalAuthorisationMissing, healthWorkout)
            }
        }
    }
    
    /**
     Saves the provided weight to the health store.
     - parameter weight: the measurement providing the weight data to be saved
     - parameter completion: the closure performed upon the completion of saving
     */
    static func saveWeight(for weight: NSMeasurement, completion: @escaping (HealthError?) -> Void) {
        
        guard weight.canBeConverted(to: UnitMass.kilograms),
              let kilograms = weight.converting(to: UnitMass.kilograms).value as Optional,
              let quantity = createHealthQuantity(value: kilograms, unit: HealthUnit.Kilogram)
        else { completion(.invalidInput); return }
        
        gainAuthorisation(for: [HealthType.BodyMass]) { authorisation, _ in
            guard authorisation else { completion(.insufficientAuthorisation); return }
            
            let timestamp = Date()
            
            let sample = HKQuantitySample(
                type: HealthType.BodyMass,
                quantity: quantity,
                start: timestamp,
                end: timestamp,
                metadata: [ HKMetadataKeyWasUserEntered : true ]
            )
            
            HealthStoreManager.healthStore.save(sample) { success, error in
                completion(error == nil ? nil : .healthKitError(error: error) )
            }
        }
    }
    
    /**
     Saves all workouts in the database to Apple Health while ignoring the ones already saved.
     - parameter completion: the closure called upon completion of saving
     - parameter error: an optional `HealthError`, when nil the operation was successful
     - parameter allSavedAlready: a boolean indicating whether all workouts were saved to Health already
     */
    static func saveAllWorkouts(completion: @escaping (_ error: HealthError?, _ allSavedAlready: Bool) -> Void) {
        
        let unsavedWorkouts: [Workout] = DataManager.queryObjects(from: \._healthKitUUID == UUID())
        guard unsavedWorkouts.count > 0 else { completion(nil, true); return }
        
        var saveCount = 0
        var errorOccured: HealthError?
        
        for workout in unsavedWorkouts {
            saveHealthWorkout(for: workout) { error, _ in
                saveCount += 1
                if error != nil {
                    errorOccured = error
                }
                guard saveCount == unsavedWorkouts.count else { return }
                completion(errorOccured, false)
            }
        }
    }
    
    // MARK: - Deletion
    
    /**
     Deletes the `HKWorkout` associated with the provided workout object from the health store.
     - parameter workout: the workout for which the associated health workout is supposed to be deleted
     - parameter completion: the closure being performed upon completion indicating if an error occured
     */
    static func deleteHealthWorkout(for workout: ORWorkoutInterface, completion: @escaping (HealthError?) -> Void) {
        
        guard let reference = workout.healthKitUUID else { completion(.invalidInput); return }
        let completion = safeClosure(from: completion)
        
        gainAuthorisation(for: [HealthType.Workout]) { workoutAuthorisation, _ in
            guard workoutAuthorisation else { completion(.insufficientAuthorisation); return }
            
            queryHealthObject(of: HealthType.Workout, with: reference) { healthWorkout, error in
                guard let healthWorkout = healthWorkout as? HKWorkout else { completion(.healthKitError(error: error)); return }
                
                let assosicationPredicate = HKQuery.predicateForObjects(from: healthWorkout)
                
                let sampleTypesToDelete = HealthType.allImplementedTypes.filter { $0 != HealthType.Workout }
                let dispatchGroup = DispatchGroup()
                var deleteCount = 0
                
                dispatchGroup.enter()
                sampleTypesToDelete.forEach { type in
                    HealthStoreManager.healthStore.deleteObjects(of: type, predicate: assosicationPredicate) { _, _, _ in
                        deleteCount += 1
                        if deleteCount == sampleTypesToDelete.count {
                            dispatchGroup.leave()
                        }
                    }
                }
                
                dispatchGroup.wait()
                
                HealthStoreManager.healthStore.delete(healthWorkout) { success, error in
                    guard success else { completion(.healthKitError(error: error)); return }
                    completion(nil)
                }
            }
        }
    }
    
    /**
     Deletes all objects created by this app from the health store.
     - parameter completion: the closure being performed upon completion
     */
    static func deleteAllObjects(completion: @escaping (HealthError?) -> Void) {
        
        let completion = safeClosure(from: completion)
        let predicate = HKQuery.predicateForObjects(from: HKSource.default())
        
        var deleteCount = 0
        
        gainAuthorisation { authorisation, authorisedTypes in
            guard authorisation else { completion(.insufficientAuthorisation); return }
            
            authorisedTypes.forEach { type in
                HealthStoreManager.healthStore.deleteObjects(of: type, predicate: predicate) { _, _, error in
                    deleteCount += 1
                    if deleteCount == HealthType.allImplementedTypes.count {
                        completion(authorisedTypes == HealthType.allImplementedTypes ? nil : .optionalAuthorisationMissing)
                    }
                }
            }
        }
    }
    
    // MARK: - Updating
    
    /**
     Updates the associated `HKWorkout` by resaving it with the new data and renewing the reference in the workout object.
     - parameter workout: the workout which is supposed to be updated in the health store
     - parameter completion: the closure being performed upon completion indicating if an error occured
     */
    static func updateHealthWorkout(for workout: ORWorkoutInterface, completion: @escaping (HealthError?) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        deleteHealthWorkout(for: workout) { deletionError in
            guard deletionError == nil else { completion(deletionError); return }
            
            saveHealthWorkout(for: workout) { savingError, _ in
                guard savingError == nil else { completion(savingError); return }
                completion(nil)
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
            
            var events = [
                HKWorkoutEvent(
                    type: .pause,
                    dateInterval: DateInterval(start: pause.startDate, duration: 0),
                    metadata: nil
                ),
                workout.endDate == pause.endDate ? nil : HKWorkoutEvent(
                    type: .resume,
                    dateInterval: DateInterval(start: pause.endDate, duration: 0),
                    metadata: nil
                )
            ]
            
            if pause.pauseType == .automatic {
                events.insert(
                    HKWorkoutEvent(
                        type: .motionPaused,
                        dateInterval: DateInterval(start: pause.startDate, duration: 0),
                        metadata: nil
                    ),
                    at: 1
                )
                events.append(
                    workout.endDate == pause.endDate ? nil : HKWorkoutEvent(
                        type: .motionResumed,
                        dateInterval: DateInterval(start: pause.endDate, duration: 0),
                        metadata: nil
                    )
                )
            }
            
            workoutEvents.append(contentsOf: events.filterNil())
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
        
        return workoutEvents
    }
    
    /**
     Builds the `HKWorkoutRoute` and attatches it to provided `HKWorkout`.
     - parameter workout: the workout object the route data is taken from
     - parameter healthWorkout: the health workout the route is supposed to be attached to
     */
    private static func createWorkoutRoute(from workout: ORWorkoutInterface, andAttachTo healthWorkout: HKWorkout) {
        
        guard !workout.routeData.isEmpty else { return }
        
        let locations = workout.routeData.compactMap { CLLocation(workout: $0) }
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: HealthStoreManager.healthStore, device: nil)
        
        routeBuilder.insertRouteData(locations) { (success, error) in
            
            guard success else { return }
            routeBuilder.finishRoute(with: healthWorkout, metadata: nil) { (route, error) in
                guard let error = error else { return }
                print("[Health] Error for saving workout route:", error.localizedDescription)
            }
        }
    }
    
    /**
     Creates health samples from the heart rate data of the provided workout.
     - parameter workout: the workout object the heart rate data is taken from
     - returns: the `HKQuantitySample`s generated from the heart rate data
     */
    private static func createHeartRateSamples(from workout: ORWorkoutInterface) -> [HKQuantitySample] {
        
        return workout.heartRates.compactMap { heartRateSample -> HKQuantitySample? in
            guard let quantity = createHealthQuantity(value: Double(heartRateSample.heartRate), unit: HealthUnit.HeartRate) else { return nil }
            
            return HKQuantitySample(
                type: HealthType.HeartRate,
                quantity: quantity,
                start: heartRateSample.timestamp,
                end: heartRateSample.timestamp
            )
        }
    }
    
    /**
     Creates a `HealthWorkout` from an `HKWorkout` and queries additional data required to form the object.
     - returns: the finished `HealthWorkout`
     */
    static func createHealthWorkout(from hkWorkout: HKWorkout) -> HealthWorkout? {
        let stepsMapper: (Int?, HKQuantity, DateInterval) -> Int = { lastValue, quantity, _ in
            lastValue ?? 0 + Int(quantity.doubleValue(for: .count()))
        }
        let heartRateMapper: ([TempWorkoutHeartRateDataSample]?, HKQuantity, DateInterval) -> [TempWorkoutHeartRateDataSample] = { lastValue, quantity, timeInterval -> [TempWorkoutHeartRateDataSample] in
            var values = lastValue ?? []
            values.append(.init(
                uuid: nil,
                heartRate: Int(quantity.doubleValue(for: HealthUnit.HeartRate)),
                timestamp: timeInterval.start
            ))
            return values
        }
        
        let steps: Int? = queryAnchoredHealthSeriesData(of: HealthType.StepCount, attachedTo: hkWorkout, transform: stepsMapper)
        let routeData: [CLLocation] = queryAnchoredWorkoutRoute(attachedTo: hkWorkout)
        let heartRates: [TempWorkoutHeartRateDataSample] = queryAnchoredHealthSeriesData(
            of: HealthType.HeartRate,  attachedTo: hkWorkout, transform: heartRateMapper) ?? []
        
        return HealthWorkout(
            hkWorkout,
            steps: steps,
            route: routeData,
            heartRates: heartRates
        )
    }
}
