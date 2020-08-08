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
    
    /// Creates a backup of all workouts currently saved in the database (or provided) and executes the completion block once finished, providing the status of success of the operation and an optional url to the created file
    static func createBackup(forWorkouts workouts: [Workout]? = nil, completion: @escaping (Bool, URL?) -> Void, progressClosure: @escaping (Double) -> Void) {
        
        DataQueryManager.getBackupData(
            forWorkouts: workouts,
            completion: { (success, data) in
                guard let data = data else {
                    completion(false, nil)
                    return
                }
                let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("/\(CustomTimeFormatting.backupTimeCode(forDate: Date())).orbup")
                do {
                    try data.write(to: fileURL)
                    completion(true, fileURL)
                } catch {
                    completion(false, nil)
                }
            },
            progressClosure: progressClosure
        )
        
    }
    
    static func insertBackup(url: URL, completion: @escaping (Bool, [Workout], [Event]) -> Void, progressClosure: @escaping (Double) -> Void) {
        
        do {
            let data = try Data(contentsOf: url)
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String:Any], let version = json["version"] as? String {
                
                switch version {
                case BackupV1.versionCode, Backup.versionCode:
                    let data: (events: [TempEvent], workouts: [TempWorkout]) = try {
                        
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
                    }()
                    DataManager.insertUniqueBackupData(tempEvents: data.events, tempWorkouts: data.workouts, completion: { (success, error, workouts, events) in
                        completion(success, workouts, events)
                    }, progressClosure: { newProgress in
                        DispatchQueue.main.async {
                            progressClosure(newProgress)
                        }
                    })
                default:
                    print("Error: Backup version invalid")
                    completion(false, [], [])
                    return
                }
                
            } else {
                print("Error: Could now extract version from Backup data")
                completion(false, [], [])
            }
            
        } catch {
            completion(false, [], [])
        }
        
    }
    
}
