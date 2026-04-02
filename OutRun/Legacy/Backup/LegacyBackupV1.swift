import Foundation

struct LegacyBackupV1: Codable {
    
    static let versionCode = "V1"
    
    let date: Date
    let version: String
    let workoutData: [LegacyRawDataModelV1.Workout]
    
    init(workouts: [LegacyRawDataModelV1.Workout]) {
        self.date = .now
        self.version = Self.versionCode
        self.workoutData = workouts
    }
}
