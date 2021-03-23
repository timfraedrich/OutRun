//
//  Backup.swift
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

typealias Backup = BackupV4

protocol BackupProtocol: Codable {
    
    static var versionCode: String { get }
    
}

struct BackupV1: BackupProtocol {
    
    static let versionCode = "V1"
    
    let date: Date
    let version: String
    let workoutData: [TempV1.Workout]
    
    init(workouts: [TempV1.Workout]) {
        self.date = Date()
        self.version = BackupV1.versionCode
        self.workoutData = workouts
    }
    
}

struct BackupV2: BackupProtocol {
    
    static let versionCode = "V2"
    
    let date: Date
    let version: String
    let workoutData: [TempV2.Workout]
    
    init(workouts: [TempV2.Workout]) {
        self.date = Date()
        self.version = BackupV2.versionCode
        self.workoutData = workouts
    }
    
}

struct BackupV3: BackupProtocol {
    
    static let versionCode = "V3"
    
    let date: Date
    let version: String
    let workoutData: [TempV3.Workout]
    let eventData: [TempV3.Event]
    
    init(workouts: [TempV3.Workout], events: [TempV3.Event]) {
        self.date = Date()
        self.version = BackupV3.versionCode
        self.workoutData = workouts
        self.eventData = events
    }
    
}

struct BackupV4: BackupProtocol {
    
    static let versionCode = "V4"
    
    let date: Date
    let version: String
    let workoutData: [TempV4.Workout]
    let eventData: [TempV4.Event]
    
    init(workouts: [TempV4.Workout], events: [TempV4.Event]) {
        self.date = Date()
        self.version = BackupV3.versionCode
        self.workoutData = workouts
        self.eventData = events
    }
    
}
