//
// OutRun
// Copyright (C) 2026 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import OutRunCore

enum LegacyBackupHelper {
    
    static func restore(from backupData: Data) throws -> [RawWorkout] {
        guard let dict = try JSONSerialization.jsonObject(with: backupData) as? [String: Any] else { throw LegacyBackupError.corruptedData }
        guard let versionString = dict["version"] as? String else { throw LegacyBackupError.missingVersion }
        guard let version = LegacyBackupVersion(rawValue: versionString) else { throw LegacyBackupError.invalidVersion }
        let decoder = JSONDecoder()
        let workouts: [RawWorkout]
        switch version {
        case .versionOne:
            let backupObject = try decoder.decode(LegacyBackup<LegacyRawDataModelV1.Workout>.self, from: backupData)
            workouts = backupObject.workoutData.map(RawWorkout.init)
        case .versionTwo:
            let backupObject = try decoder.decode(LegacyBackup<LegacyRawDataModelV2.Workout>.self, from: backupData)
            workouts = backupObject.workoutData.map(RawWorkout.init)
        case .versionThree:
            let backupObject = try decoder.decode(LegacyBackup<LegacyRawDataModelV3.Workout>.self, from: backupData)
            workouts = backupObject.workoutData.map(RawWorkout.init)
        }
        return workouts
    }
}
