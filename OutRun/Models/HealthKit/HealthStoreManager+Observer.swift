//
//  HealthStoreManager+Observer.swift
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

extension HealthStoreManager {
    
    // MARK: - General
    
    /**
     Gets an optional `HKQueryAnchor` from the provided preference object.
     - parameter preference: the UserPreference from which the data for the anchor is taken
     */
    private static func getAnchor(from preference: UserPreference.Optional<Data>) -> HKQueryAnchor? {
        guard let data = preference.value,
              let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        else { return nil }
        return anchor
    }
    
    /**
     Sets an optional `HKQueryAnchor` for the provided reference object.
     - parameter anchor: the optional anchor to be saved to the provided preference
     - parameter preference: the UserPreference to which the data is saved
     */
    private static func setAnchor(_ anchor: HKQueryAnchor?, for preference: UserPreference.Optional<Data>) {
        guard let anchor = anchor,
              let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
        else { return }
        preference.value = data
    }
    
    /**
     Executes an anchored query to keep track of changes in the health store.
     - parameter type: the type of object which changes a tracked for
     */
    private static func executeAnchoredQuery(of type: HKSampleType, predicate: NSPredicate? = nil, anchor: HKQueryAnchor?, update: @escaping ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void)) {
        
        let observer = HKAnchoredObjectQuery(
            type: type,
            predicate: predicate,
            anchor: anchor,
            limit: HKObjectQueryNoLimit,
            resultsHandler: update
        )
        
        observer.updateHandler = update
        HealthStoreManager.healthStore.execute(observer)
    }
    
    // MARK: - Workout Observer
    
    /// An optional UserPreference to save the anchor data to the workout observer
    private static let workoutObserverAnchorData = UserPreference.Optional<Data>(key: "previousWorkoutAnchorData")
    /// A wrapper for the workout observer anchor
    private static var workoutObserverAnchor: HKQueryAnchor? {
        get { getAnchor(from: workoutObserverAnchorData) }
        set { setAnchor(newValue, for: workoutObserverAnchorData) }
    }
    /// A variable to reference the last performed workout query
    private static var lastWorkoutQuery: HKAnchoredObjectQuery?
    /// The closure handling an update by the workout observer.
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
        
        workoutObserverAnchor = anchor
        
        let existingHealthUUIDs = DataManager.queryExistingHealthUUIDs()
        
        if UserPreferences.automaticallyImportNewHealthWorkouts.value && !samples.isEmpty {
            let workouts = samples.compactMap { $0 as? HKWorkout }
                .filter { existingHealthUUIDs.contains($0.uuid) }
                .compactMap { createHealthWorkout(from: $0) }
            
            DataManager.saveWorkouts(objects: workouts) { _, error, _ in
                guard let error = error else { return }
                print("[HealthStoreManager+Observer] An error occured while trying to save new health workouts:", error.debugDescription)
            }
        }
        
        if !deletedObjects.isEmpty {
            for deletedObject in deletedObjects {
                DataManager.removeHealthReference(reference: deletedObject.uuid)
            }
        }
        
    }
    
    // MARK: - Weight Observer
    
    /// An optional UserPreference to save the anchor data to the weight observer.
    private static let weightObserverAnchorData = UserPreference.Optional<Data>(key: "previousWorkoutAnchorData")
    /// A wrapper for the weight observer anchor.
    private static var weightObserverAnchor: HKQueryAnchor? {
        get { getAnchor(from: weightObserverAnchorData) }
        set { setAnchor(newValue, for: weightObserverAnchorData) }
    }
    /// A variable to reference the last performed weight query.
    private static var lastWeightQuery: HKAnchoredObjectQuery?
    /// The closure handling an update by the weight observer.
    private static let weightObserverUpdateClosure: ((HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void) = { (query, samples, deletedObjects, anchor, _) in
        
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
            HealthStoreManager.queryMostRecentWeightSample()
        }
        
        weightObserverAnchor = anchor
    }
    
    // MARK: - Observer Setup
    
    /**
     Sets up the anchored observers to react to changes in the health store.
     */
    static func setupObservers() {
        
        HealthStoreManager.gainAuthorisation(for: [HealthType.Workout]) { authorisation, _ in
            guard authorisation && UserPreferences.synchronizeWorkoutsWithAppleHealth.value else { return }
            let typePredicates = Workout.WorkoutType.allCases.map { HKQuery.predicateForWorkouts(with: $0.healthKitType) }
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: typePredicates)
            
            executeAnchoredQuery(
                of: HealthType.Workout,
                predicate: predicate,
                anchor: workoutObserverAnchor,
                update: workoutObserverUpdateClosure
            )
        }
        
        HealthStoreManager.gainAuthorisation(for: [HealthType.Workout]) { authorisation, _ in
            guard authorisation, UserPreferences.synchronizeWeightWithAppleHealth.value else { return }
            let predicate = NSCompoundPredicate(notPredicateWithSubpredicate: HKQuery.predicateForObjects(from: .default()))
            
            executeAnchoredQuery(
                of: HealthType.BodyMass,
                predicate: predicate,
                anchor: weightObserverAnchor,
                update: weightObserverUpdateClosure
            )
        }
    }
    
}
