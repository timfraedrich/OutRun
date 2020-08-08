//
//  HealthObserver.swift
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
import HealthKit

enum HealthObserver {
    
    // MARK: Workout Observer
    
    private static let previousWorkoutObserverAnchorData = UserPreference.Optional<Data>(key: "previousWorkoutAnchorData")
    private static var previousWorkoutObserverAnchor: HKQueryAnchor? {
        get {
            if let data = previousWorkoutObserverAnchorData.value {
                do {
                    let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
                    return anchor
                } catch {
                    print("Unable to restore previous anchor")
                }
            }
            return nil
        } set {
            if let anchor = newValue {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                    previousWorkoutObserverAnchorData.value = data
                } catch {
                    print("Unable to store new anchor")
                }
            }
        }
    }
    private static var lastWorkoutQuery: HKAnchoredObjectQuery?
    private static let workoutObserverUpdateClosure: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { (query, samples, deletedObjects, anchor, error) in
        
        if lastWorkoutQuery == nil {
            lastWorkoutQuery = query
        }
        
        guard UserPreferences.synchronizeWorkoutsWithAppleHealth.value, lastWorkoutQuery == query else {
            HealthStoreManager.healthStore.stop(query)
            if !UserPreferences.synchronizeWorkoutsWithAppleHealth.value {
                lastWorkoutQuery = nil
            }
            return
        }
        
        guard let samples = samples, let deletedObjects = deletedObjects else {
            print("Error: The workout observer query failed;", error?.localizedDescription as Any)
            HealthStoreManager.healthStore.stop(query)
            return
        }
        
        previousWorkoutObserverAnchor = anchor
        
        if UserPreferences.automaticallyImportNewHealthWorkouts.value && !samples.isEmpty {
            let queryObjects = samples.compactMap { (sample) -> HKWorkoutQueryObject? in
                if let sample = sample as? HKWorkout, DataQueryManager.checkForDuplicateHealthWorkout(withUUID: sample.uuid) {
                    return HKWorkoutQueryObject(sample)
                }
                return nil
            }
            var count = 0
            queryObjects.forEach { (queryObject) in
                HealthQueryManager.getAndAttatchRoute(to: queryObject) {
                    HealthQueryManager.getAndAttatchSteps(to: queryObject) {
                        // not fully implemented yet
                        //HealthQueryManager.getAndAttachHeartRate(to: queryObject) {
                            count += 1
                            if count == samples.count {
                                DataManager.saveWorkouts(for: queryObjects) { (success, error, workouts) in
                                    if !success {
                                        print("Error: could not save automatically detected new health workouts;", error ?? "")
                                    }
                                }
                            }
                        //}
                    }
                }
            }
        }
        
        if !deletedObjects.isEmpty {
            for deletedObject in deletedObjects {
                DataManager.removeHealthKitReference(for: deletedObject.uuid) { (success) in
                    if !success {
                        print("Error - Failed to remove reference from workout where hkWorkout was deleted")
                    }
                }
            }
        }
        
    }
    
    // MARK: Weight Observer
    
    private static let previousWeightObserverAnchorData = UserPreference.Optional<Data>(key: "previousWorkoutAnchorData")
    private static var previousWeightObserverAnchor: HKQueryAnchor? {
        get {
            if let data = previousWeightObserverAnchorData.value {
                do {
                    let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
                    return anchor
                } catch {
                    print("Unable to restore previous anchor")
                }
            }
            return nil
        } set {
            if let anchor = newValue {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                    previousWeightObserverAnchorData.value = data
                } catch {
                    print("Unable to store new anchor")
                }
            }
        }
    }
    private static var lastWeightQuery: HKAnchoredObjectQuery?
    private static let weightObserverUpdateClosure: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { (query, samples, deletedObjects, anchor, error) in
        
        if lastWeightQuery == nil {
            lastWeightQuery = query
        }
        
        guard UserPreferences.synchronizeWeightWithAppleHealth.value, lastWeightQuery == query else {
            HealthStoreManager.healthStore.stop(query)
            if !UserPreferences.synchronizeWeightWithAppleHealth.value {
                lastWorkoutQuery = nil
            }
            return
        }
        
        if !(samples?.isEmpty ?? true) || !(deletedObjects?.isEmpty ?? true) {
            HealthQueryManager.queryMostRecentWeightSample()
        }
        
        previousWeightObserverAnchor = anchor
        
    }
    
    // MARK: Observer Setup
    static func setupObservers() {
        
        guard UserPreferences.synchronizeWorkoutsWithAppleHealth.value || UserPreferences.synchronizeWeightWithAppleHealth.value else {
            return
        }
        
        HealthStoreManager.gainAuthorization { (success) in
            
            if success {
                
                if UserPreferences.synchronizeWorkoutsWithAppleHealth.value {
                    
                    let workoutObserver = HKAnchoredObjectQuery(
                        type: HealthStoreManager.objectTypeWorkoutType,
                        predicate: nil,
                        anchor: previousWorkoutObserverAnchor,
                        limit: HKObjectQueryNoLimit,
                        resultsHandler: workoutObserverUpdateClosure
                    )
                    
                    workoutObserver.updateHandler = workoutObserverUpdateClosure
                    HealthStoreManager.healthStore.execute(workoutObserver)
                }
                
                if UserPreferences.synchronizeWeightWithAppleHealth.value {
                    
                    let weightObserver = HKAnchoredObjectQuery(
                        type: HealthStoreManager.objectTypeBodyMass,
                        predicate: nil,
                        anchor: previousWeightObserverAnchor,
                        limit: HKObjectQueryNoLimit,
                        resultsHandler: weightObserverUpdateClosure
                    )
                    
                    weightObserver.updateHandler = weightObserverUpdateClosure
                    HealthStoreManager.healthStore.execute(weightObserver)
                }
            }
        }
    }
    
}
