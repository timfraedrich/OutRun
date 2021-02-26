//
//  BackupManager.swift
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
import UIKit

enum BackupManager {
    
    /**
     Creates a backup and saves it to a file providing it for export.
     - parameter workouts: the workouts being saved into the backup; if `nil` all workouts inside the database will be used
     - parameter completion: a closure providing the status of success of the operation and an optional url to the created file
     - parameter success: indicates the success of the completion
     - parameter url: points to the saved backup file
     - parameter progress: a closure providing the current status of creating the backup as a Float value ranging from 0 to 1
     */
    public static func createBackup(for workouts: [ORWorkoutInterface]? = nil, completion: @escaping (_ success: Bool, _ url: URL?) -> Void, progress: @escaping (Float) -> Void) {
        
        DataManager.queryBackupData(
            for: workouts,
            completion: { (error, data) in
                
                guard let data = data else {
                    completion(false, nil)
                    return
                }
                
                let directory = FileManager.default.temporaryDirectory
                let name = "/\(CustomDateFormatting.backupTimeCode(forDate: Date())).orbup"
                let url = directory.appendingPathComponent(name)
                
                do {
                    try data.write(to: url)
                    completion(true, url)
                } catch {
                    completion(false, nil)
                }
                
            },
            progress: progress
        )
        
    }
    
    /**
     Inserts the data from the backup file into the database.
     - parameter completion: a closure providing the status of success of the operation and a reference to the saved data
     - parameter success: indicates the success of the completion
     - parameter workouts: the workouts that were saved to the database
     - parameter events: the events that were saved to the database
     - parameter progress: a closure providing the current status of inserting the backup as a Float value ranging from 0 to 1
     */
    static func insertBackup(from url: URL, completion: @escaping (_ url: Bool, _ workouts: [ORWorkoutInterface], _ events: [OREventInterface]) -> Void, progress: @escaping (Float) -> Void) {
        
        
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
              let version = json["version"] as? String else {
            completion(false, [], [])
        }
        
        switch version {
        case BackupV1.versionCode, Backup.versionCode:
            
            guard let data: (events: [TempEvent], workouts: [TempWorkout]) = try? {
                
                if version == BackupV1.versionCode {
                    let oldBackup = try JSONDecoder().decode(BackupV1.self, from: data)
                    let workoutData = oldBackup.workoutData.map { (oldWorkout) -> TempWorkout in
                        return TempWorkout(fromV1: oldWorkout)
                    }
                    return (events: [], workouts: workoutData)
                    
                } else if version == BackupV2.versionCode {
                    let oldBackup = try JSONDecoder().decode(BackupV2.self, from: data)
                    let workoutData = oldBackup.workoutData.map { (oldWorkout) -> TempWorkout in
                        return TempWorkout(fromV2: oldWorkout)
                    }
                    return (events: [], workouts: workoutData)
                    
                } else {
                    let backup = try JSONDecoder().decode(Backup.self, from: data)
                    return (events: backup.eventData, workouts: backup.workoutData)
                }
            }() else {
                
                break
                
            }
            
            DataManager.insertUniqueBackupData(tempEvents: data.events, tempWorkouts: data.workouts, completion: { (success, error, workouts, events) in
                completion(success, workouts, events)
            }, progressClosure: { newProgress in
                DispatchQueue.main.async {
                    progressClosure(newProgress)
                }
            })
            
        default: break
        }
        
        completion(false, [], [])
        return
    }
    
}
