//
//  HealthStoreManager+Query.swift
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
import CoreLocation

extension HealthStoreManager {
    
    /**
     Queries the health object associated with the provided uuid if one exists.
     - parameter type: the type of the object to be returned
     - parameter uuid: the provided uuid by which the health object is identified
     - parameter completion: the closure being performed upon completion
     - parameter sample: the optional sample
     - parameter error: the error if one occured
     */
    static func queryHealthObject(of type: HKSampleType, with uuid: UUID, completion: @escaping (_ sample: HKSample?, _ error: Error?) -> Void) {
        
        let completion = safeClosure(from: completion)
        let predicate = HKQuery.predicateForObject(with: uuid)
        
        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { query, samples, error in
            
            guard let object = samples?.first else {
                completion(nil, error)
                return
            }
            
            completion(object, nil)
        }
        
        HealthStoreManager.healthStore.execute(query)
    }
    
    /**
     Queries the health objects associated with the provided workout.
     - parameter type: the type of the object to be returned
     - parameter healthWorkout: the provided uuid by which the health object is identified
     - parameter completion: the closure being performed upon completion
     - parameter samples: the optional samples
     - parameter error: the error if one occured
     */
    static func queryHealthObjects<ReturnType: HKSample>(of type: HKSampleType, limit: Int = HKObjectQueryNoLimit, attachedTo healthWorkout: HKWorkout, completion: @escaping (_ samples: [ReturnType]?, _ error: Error?) -> Void) {
        
        let completion = safeClosure(from: completion)
        let predicate = HKQuery.predicateForObjects(from: healthWorkout)
        
        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: limit,
            sortDescriptors: nil
        ) { (query, samples, error) in
            guard let samples = samples?.compactMap({ $0 as? ReturnType }) else { completion(nil, error) }
            completion(samples, error)
        }
        
        HealthStoreManager.healthStore.execute(query)
    }
    
    /**
     Searches the health store for an object with the provided type and uuid.
     - returns: a boolean indicating whether the objects exists of not
     */
    static func objectExists(of type: HKSampleType, for uuid: UUID) -> Bool {
        
        var objectExists = false
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        let predicate = HKQuery.predicateForObject(with: uuid)
        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { (query, samples, error) in
            objectExists = !(samples?.isEmpty ?? true)
            dispatchGroup.leave()
        }
        
        HealthStoreManager.healthStore.execute(query)
        dispatchGroup.wait()
        
        return objectExists
    }
    
    /**
     Queries all health workouts not saved to the database yet and retruns them asynchronously.
     - parameter completion: the closure being performed upon completion
     */
    static func queryUnsyncedHealthWorkouts(completion: @escaping (HealthError?, [HealthWorkout]) -> Void) {
        
        let completion = safeClosure(from: completion)
        
        gainAuthorisation(for: [HealthType.Workout]) { authorisation, _ in
            guard authorisation else { completion(.insufficientAuthorisation, []); return }
            
            let unsyncedWorkouts = NSCompoundPredicate(notPredicateWithSubpredicate: HKQuery.predicateForObjects(with: Set(DataManager.queryExistingHealthUUIDs())))
            let supportedTypes = NSCompoundPredicate(orPredicateWithSubpredicates: Workout.WorkoutType.allCases.map { HKQuery.predicateForWorkouts(with: $0.healthKitType) })
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [unsyncedWorkouts, supportedTypes])
            
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(
                sampleType: HealthType.Workout,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { (_, samples, error) in
                guard let hkWorkouts = samples?.compactMap({ $0 as? HKWorkout }) else {
                    completion(.healthKitError(error: error), [])
                    return
                }
                
                let healthWorkouts = hkWorkouts.compactMap(createHealthWorkout)
                completion(nil, healthWorkouts)
            }
            
            HealthStoreManager.healthStore.execute(query)
        }
    }
    
    /**
     Queries health series data attached to the provided workout and tranforms it through a provided closure before returning it allowing for both commulative results and lists being returned.
     - parameter type: the type of data being queried
     - parameter healthWorkout: the `HKWorkout` the data is attached to
     - parameter transform: the closure used to tranform the queried data before returning it
     - parameter lastValue: the last value returned by the transformClosure
     - parameter quantity: the current quantity for extracting the wanted data
     - parameter dateInterval: the quantity's date interval
     */
    static func queryAnchoredHealthSeriesData<ReturnType>(of type: HKQuantityType, attachedTo healthWorkout: HKWorkout, transform: (_ lastValue: ReturnType?, _ quantity: HKQuantity, _ dateInterval: DateInterval) -> ReturnType?) -> ReturnType? {
        
        var lastValue: ReturnType?
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        gainAuthorisation(for: [type]) { authorisation, _ in
            guard authorisation else { dispatchGroup.leave(); return }
            
            let predicate = HKAnchoredObjectQuery.predicateForObjects(from: healthWorkout)
            let query = HKQuantitySeriesSampleQuery(quantityType: type, predicate: predicate) { query, quantity, dateInterval, _, done, error in
                guard error == nil, let quantity = quantity, let dateInterval = dateInterval, let tranformedValue = transform(lastValue, quantity, dateInterval) else { return }
                
                lastValue = tranformedValue
                
                guard done else { return }
                HealthStoreManager.healthStore.stop(query)
                dispatchGroup.leave()
            }
            
            HealthStoreManager.healthStore.execute(query)
        }
        
        dispatchGroup.wait()
        return lastValue
    }
    
    /**
     Queries the workout route attachted to a health workout.
     - parameter healthRoute: the health workout the route is associated with
     - returns: the location data of the queried health workout
     */
    static func queryAnchoredWorkoutRoute(attachedTo healthWorkout: HKWorkout) -> [CLLocation] {
        
        var routeData = [CLLocation]()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        gainAuthorisation(for: [HealthType.Route]) { authorisation, _ in
            guard authorisation else { dispatchGroup.leave(); return }
            
            queryHealthObjects(
                of: HealthType.Route,
                attachedTo: healthWorkout
            ) { routes, error in
                guard let route = routes?.first as? HKWorkoutRoute else { dispatchGroup.leave(); return }
                
                let query = HKWorkoutRouteQuery(route: route) { query, locations, done, error in
                    guard let locations = locations else { dispatchGroup.leave(); return }
                    
                    routeData.append(contentsOf: locations)
                    
                    guard done else { return }
                    HealthStoreManager.healthStore.stop(query)
                    dispatchGroup.leave()
                }
                
                HealthStoreManager.healthStore.execute(query)
            }
        }
        
        dispatchGroup.wait()
        return routeData
    }
    
    /**
     Queries the most recent body weight sample from the health store and saves it to UserSettings.
     */
    static func queryMostRecentWeightSample() {
        
        let query = HKSampleQuery(
            sampleType: HealthStoreManager.HealthType.BodyMass,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { (_, samples, _) in
            guard let weight = samples?.max(by: { $0.startDate > $1.startDate }) as? HKQuantitySample else { return }
            
            let newWeightInKG = weight.quantity.doubleValue(for: HKUnit.init(from: .kilogram))
            UserPreferences.weight.value = newWeightInKG
        }
        
        HealthStoreManager.healthStore.execute(query)
    }
}
