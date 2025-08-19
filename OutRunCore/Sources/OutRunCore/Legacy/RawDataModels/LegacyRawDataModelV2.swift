import Foundation

enum LegacyRawDataModelV2 {
    
    struct Workout: Codable {
        let uuid: UUID?
        let workoutType: Int
        let startDate: Date
        let endDate: Date
        let distance: Double
        let isRace: Bool
        let isUserModified: Bool
        let comment: String?
        let burnedEnergy: Double
        let healthKitUUID: UUID?
        let locations: [RouteDataSample]
    }
    
    struct RouteDataSample: Codable {
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
}
