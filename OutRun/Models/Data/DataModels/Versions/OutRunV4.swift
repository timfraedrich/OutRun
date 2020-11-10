//
//  OutRunV4.swift
//
//  OutRun
//  Copyright (C) 2020 Tim Fraedrich <timfraedrich@icloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import CoreStore

enum OutRunV4: ORDataModel {
    
    static let identifier = "OutRunV4"
    static let schema = CoreStoreSchema(
        modelVersion: OutRunV4.identifier,
        entities: [
            Entity<OutRunV4.Workout>(OutRunV4.Workout.identifier),
            Entity<OutRunV4.WorkoutPause>(OutRunV4.WorkoutPause.identifier),
            Entity<OutRunV4.WorkoutEvent>(OutRunV4.WorkoutEvent.identifier),
            Entity<OutRunV4.WorkoutRouteDataSample>(OutRunV4.WorkoutRouteDataSample.identifier),
            Entity<OutRunV4.WorkoutHeartRateDataSample>(OutRunV4.WorkoutHeartRateDataSample.identifier),
            Entity<OutRunV4.Event>(OutRunV4.Event.identifier)
        ],
        versionLock: [
            OutRunV4.Workout.identifier: [0x236fcba032b81ba9, 0xa776b92c815cdcc0, 0x123af15289e50cd9, 0x9766946e390e574f],
            OutRunV4.WorkoutPause.identifier: [0x89c52b63c97fb5c1, 0xa652377da0a883b8, 0x43cfd39627f2cc09, 0x33ce6792256451a7],
            OutRunV4.WorkoutEvent.identifier: [0xab96203b4ad8735, 0x83a3706df06897f9, 0x499ccfb06aa82a1f, 0xb3653fd2be428391],
            OutRunV4.WorkoutRouteDataSample.identifier: [0x8fb3f3add05348dc, 0xaf69cdd28c67537, 0xeda9c05c619958f, 0x62c61c5f0f6a8978],
            OutRunV4.WorkoutHeartRateDataSample.identifier: [0xe8260e997046484b, 0x9d918b9c9db17754, 0x8aebb7846be2bf3d, 0x5e25afd102fd1221],
            OutRunV4.Event.identifier: [0xa36fbda0ab520d10, 0x9ce68b9574d00cac, 0x8ebf7e6d9b4cf7d6, 0x3453773d7b64366]
        ]
    )
    static let mappingProvider: CustomSchemaMappingProvider? = CustomSchemaMappingProvider(
        from: OutRunV3to4.identifier,
        to: OutRunV4.identifier,
        entityMappings: [
            .copyEntity(sourceEntity: OutRunV3to4.Workout.identifier, destinationEntity: OutRunV4.Workout.identifier),
            .transformEntity(
                sourceEntity: OutRunV3to4.WorkoutEvent.identifier,
                destinationEntity: OutRunV4.WorkoutEvent.identifier,
                transformer: { (sourceObject: CustomSchemaMappingProvider.UnsafeSourceObject, createDestinationObject: () -> CustomSchemaMappingProvider.UnsafeDestinationObject) in
                    
                    if let eventType = sourceObject["eventType"] as? Int, let convertedEventType = eventType - 4 as Optional, convertedEventType >= 0 {
                        
                        let destinationObject = createDestinationObject()
                        
                        destinationObject["eventType"] = convertedEventType
                        
                        destinationObject.enumerateAttributes { (attribute, sourceAttribute) in
                            if let sourceAttribute = sourceAttribute, sourceAttribute.coreStoreDumpString != "eventType" {
                                destinationObject[attribute] = sourceObject[sourceAttribute]
                            }
                        }
                    }
                }
            ),
            .copyEntity(sourceEntity: OutRunV3to4.WorkoutRouteDataSample.identifier, destinationEntity: OutRunV4.WorkoutRouteDataSample.identifier),
            .transformEntity(
                sourceEntity: OutRunV3to4.WorkoutHeartRateDataSample.identifier,
                destinationEntity: OutRunV4.WorkoutHeartRateDataSample.identifier,
                transformer: { (sourceObject: CustomSchemaMappingProvider.UnsafeSourceObject, createDestinationObject: () -> CustomSchemaMappingProvider.UnsafeDestinationObject) in
                    
                    let destinationObject = createDestinationObject()
                    
                    destinationObject["heartRate"] = Int(sourceObject["heartRate"] as! Double)
                    
                    destinationObject.enumerateAttributes { (attribute, sourceAttribute) in
                        if let sourceAttribute = sourceAttribute, sourceAttribute.coreStoreDumpString != "heartRate" {
                            destinationObject[attribute] = sourceObject[sourceAttribute]
                        }
                    }
                }
            ),
            .deleteEntity(sourceEntity: OutRunV3to4.Event.identifier),
            .insertEntity(destinationEntity: OutRunV4.Event.identifier)
        ]
    )
    static let migrationChain: [ORDataModel.Type] = [OutRunV1.self, OutRunV2.self, OutRunV3.self, OutRunV3to4.self, OutRunV4.self]
    
    // MARK: Workout
    class Workout: CoreStoreObject, ORDataType {
        
        static let identifier = "Workout"
        
        let _uuid = Value.Optional<UUID>("id")
        let _workoutType = Value.Required<Workout.WorkoutType>("workoutType", initial: .unknown)
        let _distance = Value.Required<Double>("distance", initial: -1)
        let _steps = Value.Optional<Int>("steps")
        let _startDate = Value.Required<Date>("startDate", initial: .init(timeIntervalSince1970: 0))
        let _endDate = Value.Required<Date>("endDate", initial: .init(timeIntervalSince1970: 0))
        let _burnedEnergy = Value.Optional<Double>("burnedEnergy")
        let _isRace = Value.Required<Bool>("isRace", initial: false)
        let _comment = Value.Optional<String>("comment")
        let _isUserModified = Value.Required<Bool>("isUserModified", initial: false)
        let _healthKitUUID = Value.Optional<UUID>("healthKitID")
        
        let _ascend = Value.Required<Double>("ascendingAltitude", initial: 0)
        let _descend = Value.Required<Double>("descendingAltitude", initial: 0)
        let _activeDuration = Value.Required<Double>("activeDuration", initial: 0)
        let _pauseDuration = Value.Required<Double>("pauseDuration", initial: 0)
        let _dayIdentifier = Value.Required<String>("dayIdentifier", initial: "")
        
        let _heartRates = Relationship.ToManyOrdered<OutRunV4.WorkoutHeartRateDataSample>("heartRates", inverse: { $0._workout })
        let _routeData = Relationship.ToManyOrdered<OutRunV4.WorkoutRouteDataSample>("routeData", inverse: { $0._workout })
        let _pauses = Relationship.ToManyOrdered<OutRunV4.WorkoutPause>("pauses", inverse: { $0._workout })
        let _workoutEvents = Relationship.ToManyOrdered<OutRunV4.WorkoutEvent>("workoutEvents", inverse: { $0._workout })
        let _events = Relationship.ToManyUnordered<OutRunV4.Event>("events", inverse: { $0._workouts })
        
    }
    
    // MARK: WorkoutPause
    class WorkoutPause: CoreStoreObject, ORDataType {
        
        static let identifier = "WorkoutPause"
        
        let _uuid = Value.Optional<UUID>("id")
        let _startDate = Value.Required<Date>("startDate", initial: .init(timeIntervalSince1970: 0))
        let _endDate = Value.Required<Date>("endDate", initial: .init(timeIntervalSince1970: 0))
        let _pauseType = Value.Required<WorkoutPause.WorkoutPauseType>("pauseType", initial: .manual)
        
        let _workout = Relationship.ToOne<OutRunV4.Workout>("workout")
        
    }
    
    // MARK: WorkoutEvent
    class WorkoutEvent: CoreStoreObject, ORDataType {
        
        static let identifier = "WorkoutEvent"
        
        let _uuid = Value.Optional<UUID>("id")
        let _eventType = Value.Required<WorkoutEvent.WorkoutEventType>("eventType", initial: .unknown)
        let _timestamp = Value.Required<Date>("timestamp", initial: .init(timeIntervalSince1970: 0), renamingIdentifier: "startDate")
        
        let _workout = Relationship.ToOne<OutRunV4.Workout>("workout")
        
    }
    
    // MARK: WorkoutRouteDataSample
    class WorkoutRouteDataSample: CoreStoreObject, ORDataType {
        
        static let identifier = "WorkoutRouteDataSample"
        
        let _uuid = Value.Optional<UUID>("id")
        let _timestamp = Value.Required<Date>("timestamp", initial: .init(timeIntervalSince1970: 0))
        let _latitude = Value.Required<Double>("latitude", initial: -1)
        let _longitude = Value.Required<Double>("longitude", initial: -1)
        let _altitude = Value.Required<Double>("altitude", initial: -1)
        let _horizontalAccuracy = Value.Required<Double>("horizontalAccuracy", initial: 0)
        let _verticalAccuracy = Value.Required<Double>("verticalAccuracy", initial: 0)
        let _speed = Value.Required<Double>("speed", initial: -1)
        let _direction = Value.Required<Double>("direction", initial: -1)
        
        let _workout = Relationship.ToOne<OutRunV4.Workout>("workout")
        
    }
    
    // MARK: WorkoutHeartRateDataSample
    class WorkoutHeartRateDataSample: CoreStoreObject, ORDataType {
        
        static let identifier = "WorkoutHeartRateSample"
        
        let _uuid = Value.Optional<UUID>("id")
        let _heartRate = Value.Required<Int>("heartRate", initial: 0)
        let _timestamp = Value.Required<Date>("timestamp", initial: .init(timeIntervalSince1970: 0))
        
        let _workout = Relationship.ToOne<OutRunV4.Workout>("workout")
        
    }
    
    // MARK: Event
    class Event: CoreStoreObject, ORDataType {
        
        static let identifier = "Event"
        
        let _uuid = Value.Optional<UUID>("id")
        let _title = Value.Required<String>("eventTitle", initial: "")
        let _comment = Value.Optional<String>("comment")
        let _startDate = Value.Optional<Date>("startDate")
        let _endDate = Value.Optional<Date>("endDate")
        
        let _workouts = Relationship.ToManyOrdered<OutRunV4.Workout>("workouts")
        
    }
    
}
