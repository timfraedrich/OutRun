import Foundation

struct LegacyBackupV3: Codable {
    
    static let versionCode = "V3"
    
    let date: Date
    let version: String
    let workoutData: [LegacyRawDataModelV3.Workout]
    let eventData: [LegacyRawDataModelV3.Event]
    
    init(workouts: [LegacyRawDataModelV3.Workout], events: [LegacyRawDataModelV3.Event]) {
        self.date = .now
        self.version = Self.versionCode
        self.workoutData = workouts
        self.eventData = events
    }
}
