import Foundation

enum RawDataModelV3 {
    
    struct Workout: Codable {
        let uuid: UUID?
        let workoutType: Int
        let startDate: Date
        let endDate: Date
        let distance: Double
        let steps: Int?
        let isRace: Bool
        let isUserModified: Bool
        let comment: String?
        let burnedEnergy: Double?
        let healthKitUUID: UUID?
        let workoutEvents: [WorkoutEvent]
        let locations: [WorkoutRouteDataSample]
        let heartRates: [WorkoutHeartRateDataSample]
    }
    
    struct WorkoutEvent: Codable {
        let uuid: UUID?
        let eventType: Int
        let startDate: Date
        let endDate: Date
    }
    
    struct WorkoutRouteDataSample: Codable {
        let uuid: UUID?
        let timestamp: Date
        let latitude: Double
        let longitude: Double
        let altitude: Double
        let horizontalAccuracy: Double
        let verticalAccuracy: Double
        let speed: Double
        let direction: Double
    }
    
    struct WorkoutHeartRateDataSample: Codable {
        let uuid: UUID?
        let heartRate: Double
        let timestamp: Date
    }
    
    struct Event: Codable {
        let uuid: UUID?
        let title: String
        let comment: String?
        let startDate: Date?
        let endDate: Date?
        let workouts: [UUID]
    }
}
