import Foundation

enum RawDataModelV1 {
    
    struct Workout: Codable {
        let uuid: UUID?
        let workoutType: Int
        let startDate: Date
        let endDate: Date
        let distance: Double
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
        let speed: Double
        let direction: Double
    }
}
