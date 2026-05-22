@unsafe @preconcurrency import CoreStore
import Foundation

enum LegacyDataModelV1: LegacyDataModel {
    
    static let identifier = "OutRunV1"
    static let schema = CoreStoreSchema(
        modelVersion: LegacyDataModelV1.identifier,
        entities: [
            Entity<LegacyDataModelV1.Workout>(LegacyDataModelV1.Workout.identifier),
            Entity<LegacyDataModelV1.RouteDataSample>(LegacyDataModelV1.RouteDataSample.identifier)
        ],
        versionLock: [
            LegacyDataModelV1.RouteDataSample.identifier: [0xc916902e15f798ae, 0x9442db47c2de4ef2, 0x85478c6d328fdb99, 0x9829e4d715772eda],
            LegacyDataModelV1.Workout.identifier: [0xc693e96b19a41fc7, 0x6efcd5a65d69bc94, 0x947466048287185e, 0x52c58ad8b3e00d36]
        ]
    )
    static let mappingProvider: CustomSchemaMappingProvider? = nil
    static let migrationChain: [any LegacyDataModel.Type] = [LegacyDataModelV1.self]
    
    // MARK: Workout
    class Workout: CoreStoreObject {
        
        static let identifier = "Workout"
        
        let uuid = Value.Optional<UUID>("id")
        let workoutType = Value.Required<Int>("workoutType", initial: -1)
        let startDate = Value.Optional<Date>("startDate")
        let endDate = Value.Optional<Date>("endDate")
        let dayIdentifier = Value.Optional<String>("dayIdentifier")
        let distance = Value.Required<Double>("distance", initial: -1)
        let burnedEnergy = Value.Optional<Double>("burnedEnergy")
        let healthKitUUID = Value.Optional<UUID>("healthKitID")
        
        let routeDataSamples = Relationship.ToManyOrdered<LegacyDataModelV1.RouteDataSample>("routeDataSamples", inverse: { $0.workout })
        
    }
    
    // MARK: Route Data Sample
    class RouteDataSample: CoreStoreObject {
        
        static let identifier = "RouteDataSample"
        
        let id = Value.Optional<UUID>("id")
        let timestamp = Value.Optional<Date>("timestamp")
        let latitude = Value.Required<Double>("latitude", initial: -1)
        let longitude = Value.Required<Double>("longitude", initial: -1)
        let altitude = Value.Required<Double>("altitude", initial: -1)
        let speed = Value.Required<Double>("speed", initial: -1)
        let direction = Value.Required<Double>("direction", initial: -1)
        
        let workout = Relationship.ToOne<LegacyDataModelV1.Workout>("workout")
        
    }
    
}
