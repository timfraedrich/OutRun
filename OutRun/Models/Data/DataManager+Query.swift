//
//  DataManager+Query.swift
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

extension DataManager {
    
    // MARK: - General
    
    /**
     Queries the an object comforming to `ORDataType` with the provided `UUID` from the database.
     - parameter uuid: the `UUID` of the workout that is supposed to be returned; if `nil` this function will return immediately with no value
     - parameter transaction: an optional `AsynchronousDataTransaction` to be provided if the workout needs to be queried during a tranaction; if `nil` the object will be queried from the `DataManager.dataStack`
     - returns: the wanted `ORDataType` object if one could be found in the database; if the object could not be found, this function will return `nil`
     */
    public static func queryObject<ObjectType: ORDataType>(from uuid: UUID?, transaction: AsynchronousDataTransaction? = nil) -> ObjectType? {
        
        guard let uuid = uuid else {
            return nil
        }
        
        let object = try? (transaction as FetchableSource? ?? dataStack).fetchOne(From<ObjectType>().where(\._uuid == uuid))
        return object
        
    }
    
    /**
     Queries the count for objects of the given `ORDataType` and `UUID` returning whether it has duplicates in the database.
     - parameter uuid: the `UUID` of the workout being checked for duplicates; if `nil` this function will return immediately with `false`
     - parameter objectType: the type of the object being checked for duplicates
     - returns: `true` if the queried count is anything other than 0 meaning there are workouts with the given `UUID` present in the database.
     */
    public static func objectHasDuplicate<ObjectType: ORDataType>(uuid: UUID?, objectType: ObjectType.Type) -> Bool {
        
        
        guard let uuid = uuid else {
            return false
        }
        
        if let count = try? dataStack.fetchCount(From<ObjectType>().where(\._uuid == uuid)) {
            return count != 0
        }
        
        return false
        
    }
    
    /**
     Fetches the count of saved objects of a specific `ORObjectType` inside the database.
     - parameter of: the kind of `ORObjectType` to fetch the count of
     - returns: the number of counted objects as an `Int`
     */
    public static func fetchCount<ObjectType: ORDataType>(of _: ObjectType.Type) -> Int {
        let count = try? dataStack.fetchCount(From<ObjectType>())
        return count ?? 0
    }
    
    // MARK: - Workout Route
    
    /**
     Queries the route of a workout and converts each route sample into the corresponding `CLLocationDegrees`.
     - parameter workout: the object the route is going to be queried from, any `ORWorkoutInterface` will be accepted
     - parameter completion: the closure being called upon completion of the query
     - parameter success: indicates whether or not the query succeeded
     - parameter error: provides more detail on a query failure if one occured
     - parameter coordinates: the queried array of `CLLocationCoordinate2D`
     */
    public static func asyncLocationCoordinatesQuery(for workout: ORWorkoutInterface, completion: @escaping (_ error: LocationQueryError?, _ coordinates: [CLLocationCoordinate2D]) -> Void) {
        
        var error: LocationQueryError?
        
        dataStack.perform(asynchronous: { (transaction) -> [CLLocationCoordinate2D] in
            
            guard let workout = (workout as? Workout) ?? queryObject(from: workout.uuid, transaction: transaction) else {
                error = .notSaved
                return []
            }
            
            let samples = workout._routeData.value
            guard !samples.isEmpty else {
                error = .noRouteData
                return []
            }
            
            return samples.map { (sample) -> CLLocationCoordinate2D in
                CLLocationCoordinate2D(
                    latitude: sample._latitude.value,
                    longitude: sample._longitude.value
                )
            }
            
        }) { (result) in
            switch result {
            case .success(let coordinates):
                completion(error, coordinates)
            case .failure(let error):
                completion(.databaseError(error: error), [])
            }
        }
    }
    
    // MARK: - Backup
    
    /**
     Queries the data required to create a backup.
     - parameter workouts:
     - parameter completion:
     - parameter progress
     */
    public static func queryBackupData(for workouts: [ORWorkoutInterface]? = nil, completion: @escaping (_ error: Error?, _ data: Data?) -> Void, progress: @escaping (Float) -> Void) {
        
        dataStack.perform(asynchronous: { (transaction) -> Data? in
            do {
                let queryWorkouts: [Workout] = try {
                    if workouts != nil {
                        let workouts = transaction.fetchExisting(workouts!)
                        return workouts
                    }
                    return try transaction.fetchAll(From<Workout>())
                }()
                
                let queryEvents: [Event] = try {
                    if let events = events {
                        return events
                    }
                    return try transaction.fetchAll(From<Event>())
                }()
                
                let totalCount = Double(queryWorkouts.count + queryEvents.count)
                
                let tempWorkouts = queryWorkouts.enumerated().map { (index, workout) -> TempWorkout in
                    let progress = Double(index + 1) / totalCount
                    progressClosure(progress)
                    return TempWorkout(workout: workout)
                }
                
                let tempEvents = queryEvents.enumerated().map { (index, event) -> TempEvent in
                    let progress = Double(queryWorkouts.count + index + 1) / totalCount
                    progressClosure(progress)
                    return TempEvent(event: event)
                }
                
                let backup = Backup(workouts: tempWorkouts, events: tempEvents)
                
                let json = try JSONEncoder().encode(backup)
                return json
            } catch {
                print("[DataQueryManager] Failed to convert workouts to data")
                return nil
            }
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    guard let data = data else {
                        completion(false, nil)
                        return
                    }
                    completion(true, data)
                case .failure(let error):
                    completion(false, nil)
                    print("[DataQueryManager] Failed to perform transaction to convert workouts to data:", error)
                }
            }
        }
        
        
    }
    
}
