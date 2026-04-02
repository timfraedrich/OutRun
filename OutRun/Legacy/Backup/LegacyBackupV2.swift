import Foundation

struct LegacyBackupV2: Codable {
    
    static let versionCode = "V2"
    
    let date: Date
    let version: String
    let workoutData: [LegacyRawDataModelV2.Workout]
    
    init(workouts: [LegacyRawDataModelV2.Workout]) {
        self.date = .now
        self.version = Self.versionCode
        self.workoutData = workouts
    }
}
