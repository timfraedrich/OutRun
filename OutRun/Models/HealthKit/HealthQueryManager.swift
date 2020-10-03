//
//  HealthQueryManager.swift
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

enum HealthQueryManager {
    
    // MARK: Query External Health Workouts
    static func queryExternalWorkouts(completion: @escaping (Bool, [HKWorkoutQueryObject]) -> Void) {
        
        let safeCompletion: (Bool, [HKWorkoutQueryObject]) -> Void = { (success, queryObjects) in
            DispatchQueue.main.async {
                completion(success, queryObjects)
            }
        }
        
        HealthStoreManager.gainAuthorization { (success) in
        
            if success {
                
                let existingHKWorkouts = DataQueryManager.getAllExistingHealthKitWorkoutUUIDs()
                let set = Set(existingHKWorkouts)
                
                let existingPredicate = HKQuery.predicateForObjects(with: set)
                let notExistingPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: existingPredicate)
                let workoutPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
                    HKSampleQuery.predicateForWorkouts(with: .walking),
                    HKSampleQuery.predicateForWorkouts(with: .running),
                    HKSampleQuery.predicateForWorkouts(with: .cycling),
                    HKSampleQuery.predicateForWorkouts(with: .hiking),
                    HKSampleQuery.predicateForWorkouts(with: .skatingSports)
                ])
                let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [notExistingPredicate, workoutPredicate])
                
                let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
                
                let query = HKSampleQuery(sampleType: .workoutType(), predicate: queryPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor], resultsHandler: { (query, samples, error) in
                    
                    guard let samples = samples as? [HKWorkout] else {
                        safeCompletion(false, [])
                        return
                    }

                    DispatchQueue.main.async {

                        var queryObjects = [HKWorkoutQueryObject]()
                        var count = 0

                        func completeIfAppropriate() {
                            if count == samples.count {
                                safeCompletion(true, queryObjects)
                            }
                        }
                        completeIfAppropriate()
                        samples.forEach { (workout) in
                            guard let queryObject = HKWorkoutQueryObject(workout) else {
                                count += 1
                                completeIfAppropriate()
                                return
                            }
                            queryObjects.append(queryObject)
                            HealthQueryManager.getAndAttatchRoute(to: queryObject) {
                                HealthQueryManager.getAndAttatchSteps(to: queryObject) {
                                        count += 1
                                        completeIfAppropriate()
                                }
                            }
                        }
                    }

                })
                HealthStoreManager.healthStore.execute(query)
                
            } else {
                
                safeCompletion(false, [])
                
            }
            
        }
    }
    
    // MARK: Query Steps and Attatch to Query Object
    static func getAndAttatchSteps(to queryObject: HKWorkoutQueryObject, completion: @escaping () -> Void) {

        let predicate = HKAnchoredObjectQuery.predicateForObjects(from: queryObject.hkWorkout)
        let stepsQuery = HKAnchoredObjectQuery(type: HealthStoreManager.objectTypeRouteType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { (query, stepsSamples, _, _, error) in
            
            guard let stepsSamples = stepsSamples as? [HKQuantitySample] else {
                completion()
                return
            }
            
            var steps = Int()
            for sample in stepsSamples {
                steps += Int(sample.quantity.doubleValue(for: HKUnit.count()))
            }
            
            queryObject.steps = steps != 0 ? steps : nil
            completion()
        }
        
        HealthStoreManager.healthStore.execute(stepsQuery)
        
    }
    
    // MARK: Query Route and Attatch to Query Object
    static func getAndAttatchRoute(to queryObject: HKWorkoutQueryObject, completion: @escaping () -> Void) {

        let predicate = HKAnchoredObjectQuery.predicateForObjects(from: queryObject.hkWorkout)
        let routeObjectQuery = HKAnchoredObjectQuery(type: HealthStoreManager.objectTypeRouteType, predicate: predicate, anchor: nil, limit: 1) { (query, routeSamples, _, _, error) in
            
            guard let route = routeSamples?.first(where: { (sample) -> Bool in
                sample is HKWorkoutRoute
            }) as? HKWorkoutRoute else {
                print("Error - could not parse HKSample to HKWorkoutRoute")
                completion()
                return
            }
            
            let routeQuery = HKWorkoutRouteQuery(route: route) { (query, locations, success, error) in
                
                guard let locs = locations?.compactMap({ (location) -> TempWorkoutRouteDataSample? in
                    return TempWorkoutRouteDataSample(clLocation: location)
                }), locations != [] else {
                    completion()
                    return
                }
                queryObject.locations.append(contentsOf: locs)
                completion()
            }
            HealthStoreManager.healthStore.execute(routeQuery)
        }
        
        HealthStoreManager.healthStore.execute(routeObjectQuery)
    }

    // MARK: Query Heart Rates from timestamps
    static func getHeartRateSamples(startDate:Date, endDate:Date, completion: @escaping (_: [TempWorkoutHeartRateDataSample])->Void) {

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let heartRateQuery = HKAnchoredObjectQuery(type: HealthStoreManager.objectTypeHeartRate, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { (query, heartRateSamples, _, _, error) in
            guard let heartRateSamples = heartRateSamples, !heartRateSamples.isEmpty else {
                completion([])
                return
            }
            
            let samples = heartRateSamples.compactMap { (sample) -> HKQuantitySample? in
                return (sample as? HKQuantitySample ?? nil)
            }
            
            var tempSamples = [TempWorkoutHeartRateDataSample]()
            if #available(iOS 12.0, *) {
                
                func checkIfDone(_ done: Bool) {
                    if done {
                        
                        completion(tempSamples)
                    }
                }
                
                func processQuantity(query: HKQuery, quantity: HKQuantity?, date: Date?, done: Bool, error: Error?) {
                    guard let quantity = quantity, let date = date else {
                        checkIfDone(done)
                        return
                    }
                    let heartRate = quantity.doubleValue(for: HealthStoreManager.heartRateUnit)
                    let tempSample = TempWorkoutHeartRateDataSample(uuid: nil, heartRate: heartRate, timestamp: date)
                    tempSamples.append(tempSample)
                    
                    checkIfDone(done)
                    if done {
                        HealthStoreManager.healthStore.stop(query)
                    }
                }
                
                if #available(iOS 13.0, *) {
                    let query = HKQuantitySeriesSampleQuery(quantityType: HealthStoreManager.objectTypeHeartRate, predicate: predicate) { (query, quantity, dateInterval, sample, done, error) in
                        processQuantity(query: query, quantity: quantity, date: dateInterval?.start, done: done, error: error)
                    }
                    HealthStoreManager.healthStore.execute(query)
                    
                } else {
                    let sample = samples.first!
                    let query = HKQuantitySeriesSampleQuery(sample: sample) { (query, quantity, date, done, error) in
                        processQuantity(query: query, quantity: quantity, date: date, done: done, error: error)
                    }
                    HealthStoreManager.healthStore.execute(query)
                }
                
            } else {
                
                for (index, sample) in samples.enumerated() {
                    let heartRate = sample.quantity.doubleValue(for: HealthStoreManager.heartRateUnit)
                    let tempSample = TempWorkoutHeartRateDataSample(uuid: nil, heartRate: heartRate, timestamp: sample.startDate)
                    tempSamples.append(tempSample)
                    
                    if (index + 1) == samples.count {
                        
                        completion(tempSamples)
                    }
                }
            }
        }
        
        HealthStoreManager.healthStore.execute(heartRateQuery)
    }
    
    // MARK: Query Most Recent Weight And Save To UserPreferences
    static func queryMostRecentWeightSample() {
        
        let query = HKSampleQuery(
            sampleType: HealthStoreManager.objectTypeBodyMass,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { (query, samples, error) in
            
            guard let newestWeightSample = samples?.max(by: { (sample1, sample2) -> Bool in
                return sample1.startDate > sample2.startDate
            }) as? HKQuantitySample else {
                return
            }
            
            let newWeightInKG = newestWeightSample.quantity.doubleValue(for: HKUnit.init(from: .kilogram))
            
            UserPreferences.weight.value = newWeightInKG
        }
        
        HealthStoreManager.healthStore.execute(query)
        
    }
    
}
