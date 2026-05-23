import Foundation
import CoreStore

enum LegacyRawDataModelV3 {
    
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
        
        init(
            uuid: UUID?, workoutType: Int,
            startDate: Date,
            endDate: Date,
            distance: Double,
            steps: Int?,
            isRace: Bool,
            isUserModified: Bool,
            comment: String?,
            burnedEnergy: Double?,
            healthKitUUID: UUID?,
            workoutEvents: [WorkoutEvent],
            locations: [WorkoutRouteDataSample],
            heartRates: [WorkoutHeartRateDataSample]
        ) {
            self.uuid = uuid
            self.workoutType = workoutType
            self.startDate = startDate
            self.endDate = endDate
            self.distance = distance
            self.steps = steps
            self.isRace = isRace
            self.isUserModified = isUserModified
            self.comment = comment
            self.burnedEnergy = burnedEnergy
            self.healthKitUUID = healthKitUUID
            self.workoutEvents = workoutEvents
            self.locations = locations
            self.heartRates = heartRates
        }
        
        init(workout: LegacyDataModelV3.Workout) {
            uuid = workout.uuid.value
            workoutType = workout.workoutType.value
            startDate = workout.startDate.value
            endDate = workout.endDate.value
            distance = workout.distance.value
            steps = workout.steps.value
            isRace = workout.isRace.value
            isUserModified = workout.isUserModified.value
            comment = workout.comment.value
            burnedEnergy = workout.burnedEnergy.value
            healthKitUUID = workout.healthKitUUID.value
            workoutEvents = workout.workoutEvents.value.map(WorkoutEvent.init)
            locations = workout.routeData.value.map(WorkoutRouteDataSample.init)
            heartRates = workout.heartRates.value.map(WorkoutHeartRateDataSample.init)
        }
    }
    
    struct WorkoutEvent: Codable {
        let uuid: UUID?
        let eventType: Int
        let startDate: Date
        let endDate: Date
        
        init(uuid: UUID?, eventType: Int, startDate: Date, endDate: Date) {
            self.uuid = uuid
            self.eventType = eventType
            self.startDate = startDate
            self.endDate = endDate
        }
        
        init(workoutEvent: LegacyDataModelV3.WorkoutEvent) {
            uuid = workoutEvent.uuid.value
            eventType = workoutEvent.eventType.value
            startDate = workoutEvent.startDate.value
            endDate = workoutEvent.endDate.value
        }
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
        
        init(
            uuid: UUID?,
            timestamp: Date,
            latitude: Double,
            longitude: Double,
            altitude: Double,
            horizontalAccuracy: Double,
            verticalAccuracy: Double,
            speed: Double,
            direction: Double
        ) {
            self.uuid = uuid
            self.timestamp = timestamp
            self.latitude = latitude
            self.longitude = longitude
            self.altitude = altitude
            self.horizontalAccuracy = horizontalAccuracy
            self.verticalAccuracy = verticalAccuracy
            self.speed = speed
            self.direction = direction
        }
        
        init(routeDataSample: LegacyDataModelV3.WorkoutRouteDataSample) {
            uuid = routeDataSample.uuid.value
            timestamp = routeDataSample.timestamp.value
            latitude = routeDataSample.latitude.value
            longitude = routeDataSample.longitude.value
            altitude = routeDataSample.altitude.value
            horizontalAccuracy = routeDataSample.horizontalAccuracy.value
            verticalAccuracy = routeDataSample.verticalAccuracy.value
            speed = routeDataSample.speed.value
            direction = routeDataSample.direction.value
        }
    }
    
    struct WorkoutHeartRateDataSample: Codable {
        let uuid: UUID?
        let heartRate: Double
        let timestamp: Date
        
        init(uuid: UUID?, heartRate: Double, timestamp: Date) {
            self.uuid = uuid
            self.heartRate = heartRate
            self.timestamp = timestamp
        }
        
        init(heartRateDataSample: LegacyDataModelV3.WorkoutHeartRateDataSample) {
            uuid = heartRateDataSample.uuid.value
            heartRate = heartRateDataSample.heartRate.value
            timestamp = heartRateDataSample.timestamp.value
        }
    }
    
    struct Event: Codable {
        let uuid: UUID?
        let title: String
        let comment: String?
        let startDate: Date?
        let endDate: Date?
        let workouts: [UUID]
        
        init(uuid: UUID?, title: String, comment: String?, startDate: Date?, endDate: Date?, workouts: [UUID]) {
            self.uuid = uuid
            self.title = title
            self.comment = comment
            self.startDate = startDate
            self.endDate = endDate
            self.workouts = workouts
        }
        
        init(event: LegacyDataModelV3.Event) {
            uuid = event.uuid.value
            title = event.title.value
            comment = event.comment.value
            startDate = event.startDate.value
            endDate = event.endDate.value
            workouts = event.workouts.value.compactMap(\.uuid.value)
        }
    }
}
