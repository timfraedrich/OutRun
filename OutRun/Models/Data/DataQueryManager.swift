//
//  DataQueryManager.swift
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

enum DataQueryManager {
    
    // MARK: Fetch Location Degrees
    static func fetchLocationDegreesOfRoute(fromWorkoutID uuid: UUID, completion: @escaping (Bool, [CLLocationCoordinate2D]?) -> Void) {
        
        DataManager.dataStack.perform(asynchronous: { (transaction) -> [CLLocationCoordinate2D]? in
            
            do {
                guard let tempWorkout = try transaction.fetchOne(From<Workout>().where(\.uuid == uuid)) else {
                    return nil
                }
                let samples = tempWorkout.routeData.value
                let degrees = samples.map { (sample) -> CLLocationCoordinate2D in
                    return CLLocationCoordinate2D(latitude: sample.latitude.value, longitude: sample.longitude.value)
                }
                return degrees
            } catch {
                print("[DataQueryManager] Failed to fetch locations from workout")
                return nil
            }
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let degrees):
                    guard let degrees = degrees else {
                        completion(false, nil)
                        return
                    }
                    completion(true, degrees)
                case .failure(let error):
                    completion(false, nil)
                    print("[DataQueryManager] Failed to perform transaction to query locations from workout:", error)
                }
            }
        }
    }
    
    // MARK: Query backup data
    static func getBackupData(forWorkouts workouts: [Workout]? = nil, andEvents events: [Event]? = nil, completion: @escaping (Bool, Data?) -> Void, progressClosure: @escaping (Double) -> Void) {
        
        DataManager.dataStack.perform(asynchronous: { (transaction) -> Data? in
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
    
    // MARK: check for health workout duplicates
    static func checkForDuplicateHealthWorkout(withUUID uuid: UUID) -> Bool {
        
        var hasDuplicate = false
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        DispatchQueue.main.async {
            do {
                let count = try DataManager.dataStack.fetchCount(From<Workout>().where(\.healthKitUUID == uuid))
                hasDuplicate = count != 0
            } catch {
                print("[DataQueryManager] Failed to fetch count of duplicate health workouts")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        
        return hasDuplicate
    }
    
    static func getAllExistingHealthKitWorkoutUUIDs() -> [UUID] {
        do {
            let workoutUUIDDicts = try DataManager.dataStack.queryAttributes(
                From<Workout>()
                    .select(NSDictionary.self, .attribute(\.healthKitUUID))
                    .where(\.healthKitUUID != nil)
            )
            
            let uuids = workoutUUIDDicts.compactMap { (dict) -> UUID? in
                guard let id = UUID(uuidString: dict.first?.value as? String ?? "") else {
                    print("[DataQueryManager] Unexpectedly found HKWorkout uuid nil while mapping")
                    return nil
                }
                return id
            }
            
            return uuids
            
        } catch {
            print("[DataQueryManager] Failed to query HKWorkout uuids in database")
            return []
        }
    }
    
    static func queryAllWorkoutsWithoutAppleHealthReference(completion: @escaping (Bool, [Workout]) -> Void) {
        
        DataManager.dataStack.perform(asynchronous: { (transaction) -> [Workout] in
            
            do {
                let workouts = try transaction.fetchAll(From<Workout>().where(\.healthKitUUID == nil))
                return workouts
            } catch {
                return []
            }
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let tempWorkouts):
                    let workouts = DataManager.dataStack.fetchExisting(tempWorkouts)
                    completion(true, workouts)
                case .failure(let error):
                    completion(false, [])
                    print("[DataQueryManager] Error - Failed to query workouts without apple health reference:", error.debugDescription)
                }
            }
        }
    }
    
    static func queryStats(for workout: Workout, completion: @escaping (WorkoutStats?) -> Void) {
        
        DataManager.dataStack.perform(asynchronous: { (transaction) -> WorkoutStats? in
            
            if let stats = workout.cachedStats {
                return stats
            }
            
            guard let workout = transaction.fetchExisting(workout) else {
                return nil
            }
            
            let stats = WorkoutStats(workout: workout)
            workout.cachedStats = stats
            return stats
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    completion(stats)
                case .failure(let error):
                    completion(nil)
                    print("[DataQueryManager] Error - Failed to query workouts without apple health reference:", error.debugDescription)
                }
            }
        }
    }
    
    static private func getPauses(for workout: Workout) -> [(NSMeasurement, NSMeasurement?)] {
        var pauses = [(NSMeasurement, NSMeasurement?)]()
        var pauseDate: Date?
        let events = workout.workoutEvents.value
        events.enumerated().forEach { (index, event) in
            if (event.type == .pause || event.type == .autoPause), pauseDate == nil {
                pauseDate = event.startDate.value
                
            } else if (event.type == .resume || event.type == .autoResume), let pause = pauseDate {
                let pause = NSMeasurement(doubleValue: workout.startDate.value.distance(to: pause), unit: UnitDuration.seconds)
                let resume = NSMeasurement(doubleValue: workout.startDate.value.distance(to: event.startDate.value), unit: UnitDuration.seconds)
                pauses.append((pause, resume))
                pauseDate = nil
            }
            
            if (index + 1) == events.count, let pause = pauseDate {
                let pause = NSMeasurement(doubleValue: workout.startDate.value.distance(to: pause), unit: UnitDuration.seconds)
                pauses.append((pause, nil))
            }
        }
        return pauses
    }
    
    static func queryStatsSeries<T: WorkoutSeriesDataSampleType>(for workout: Workout, sampleType: T.Type, dataPoint: @escaping (Workout, T) -> (time: TimeInterval, value: Double, unit: Unit), completion: @escaping (Bool, WorkoutStatsSeries?) -> Void) {
        
        DataManager.dataStack.perform(asynchronous: { (transaction) -> (WorkoutStatsSeries?) in
            
            let tempWorkout = transaction.fetchExisting(workout)!
            guard let samples: [T] = {
                if T.self == WorkoutRouteDataSample.self {
                    return tempWorkout.routeData.value as? [T]
                } else if T.self == WorkoutHeartRateDataSample.self {
                    return tempWorkout.heartRates.value as? [T]
                } else {
                    return nil
                }
            }() else {
                return nil
            }
            
            let pauseRanges = tempWorkout.pauseRanges
            
            var currentlyPaused = false
            var finishedSeriesSections: [WorkoutStatsSeriesSection] = []
            var currentSamples: [T] = []
            var currentSectionData: [(x: NSMeasurement, y: NSMeasurement)] = []
            
            func createAndAddSectionFromData() {
                if !currentSectionData.isEmpty {
                    
                    let section = WorkoutStatsSeriesSection(
                        type: currentlyPaused ? .paused : .active,
                        data: currentSectionData,
                        associatedDataSamples: currentSamples.compactMap({ (sample) -> TempWorkoutSeriesDataSampleType? in
                            if T.self == WorkoutRouteDataSample.self {
                                return TempWorkoutRouteDataSample(sample: sample)
                            } else if T.self == WorkoutHeartRateDataSample.self {
                                return TempWorkoutHeartRateDataSample(sample: sample)
                            } else {
                                return nil
                            }
                        })
                    )
                    finishedSeriesSections.append(section)
                    
                    if let lastSample = currentSamples.last, let lastDataPoint = currentSectionData.last {
                        currentSamples = []
                        currentSectionData = []
                        currentSamples.append(lastSample)
                        currentSectionData.append(lastDataPoint)
                    } else {
                        currentSamples = []
                        currentSectionData = []
                    }
                    
                }
            }
            
            for (index, sample) in samples.enumerated() {
                
                let dataPoint = dataPoint(tempWorkout, sample)
                let x = NSMeasurement(doubleValue: dataPoint.time, unit: UnitDuration.seconds)
                let y = NSMeasurement(doubleValue: dataPoint.value, unit: dataPoint.unit)
                let dataObject = (x: x, y: y)
                
                let relativeTimeStamp = dataPoint.time
                let isPaused = pauseRanges.contains { (range) -> Bool in
                    range.contains(relativeTimeStamp)
                }
                
                if isPaused != currentlyPaused {
                    createAndAddSectionFromData()
                    currentlyPaused = isPaused
                }
                    
                currentSectionData.append(dataObject)
                currentSamples.append(sample)
                
                if index == samples.count - 1 {
                    createAndAddSectionFromData()
                }
            }
            
            return WorkoutStatsSeries(sectioningType: .activeAndPaused, sections: finishedSeriesSections)
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let series):
                    completion(true, series)
                case .failure(let error):
                    completion(false, nil)
                    print("[DataQueryManager] Failed to perform transaction to query stats series from workout:", error)
                }
            }
        }
    }
    
    static func querySectionedSampleSeries<T: WorkoutSeriesDataSampleType>(for workout: Workout, sampleType: T.Type, completion: @escaping (Bool, [(type: WorkoutStatsSeriesSection.SectionType, samples: [TempWorkoutSeriesDataSampleType])]) -> Void ) {
        
        DataManager.dataStack.perform(asynchronous: { (transaction) -> ([(type: WorkoutStatsSeriesSection.SectionType, samples: [TempWorkoutSeriesDataSampleType])]?) in
            
            let tempWorkout = transaction.fetchExisting(workout)!
            guard let samples: [T] = {
                if T.self == WorkoutRouteDataSample.self {
                    return tempWorkout.routeData.value as? [T]
                } else if T.self == WorkoutHeartRateDataSample.self {
                    return tempWorkout.heartRates.value as? [T]
                } else {
                    return nil
                }
            }() else {
                return nil
            }
            
            let pauseRanges = tempWorkout.pauseRanges
            
            var sectionArray: [(type: WorkoutStatsSeriesSection.SectionType, samples: [TempWorkoutSeriesDataSampleType])] = []
            
            var currentlyPaused = false
            var currentSamples: [T] = []
            
            func createSection() {
                if !currentSamples.isEmpty {
                    sectionArray.append(
                        (
                            type: currentlyPaused ? .paused : .active,
                            samples: currentSamples.compactMap({ (sample) -> TempWorkoutSeriesDataSampleType? in
                                if T.self == WorkoutRouteDataSample.self {
                                    return TempWorkoutRouteDataSample(sample: sample)
                                } else if T.self == WorkoutHeartRateDataSample.self {
                                    return TempWorkoutHeartRateDataSample(sample: sample)
                                } else {
                                    return nil
                                }
                            })
                        )
                    )
                }
            }
            
            for (index, sample) in samples.enumerated() {
                
                let relativeTimeStamp: TimeInterval
                if let routeSample = sample as? WorkoutRouteDataSample {
                    relativeTimeStamp = tempWorkout.startDate.value.distance(to: routeSample.timestamp.value)
                } else if let heartSample = sample as? WorkoutHeartRateDataSample {
                    relativeTimeStamp = tempWorkout.startDate.value.distance(to: heartSample.timestamp.value)
                } else {
                    continue
                }
                
                let isPaused = pauseRanges.contains { (range) -> Bool in
                    range.contains(relativeTimeStamp)
                }
                
                if isPaused != currentlyPaused {
                    createSection()
                    currentlyPaused = isPaused
                }
                
                currentSamples.append(sample)
                
                if index == samples.count - 1 {
                    createSection()
                }
            }
            
            return sectionArray
            
        }) { (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let sections):
                    completion(sections != nil, sections ?? [])
                case .failure(let error):
                    completion(false, [])
                    print("[DataQueryManager] Failed to perform transaction to query sectioned location data:", error)
                }
            }
        }
        
    }
    
    static func fetchCount<Object: CoreStoreObject>(of: Object.Type) -> Int {
        do {
            return try DataManager.dataStack.fetchCount(From<Object>())
        } catch {
            print("[DataQueryManager] Failed to fetch count of \(Object.self)")
            return -1
        }
    }
    
}
