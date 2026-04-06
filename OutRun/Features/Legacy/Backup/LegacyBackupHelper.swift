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
