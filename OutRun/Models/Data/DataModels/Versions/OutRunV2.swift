//
//  OutRunV2.swift
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

enum OutRunV2 {
    
    static let identifier = "OutRunV2"
    static let schema = CoreStoreSchema(
        modelVersion: OutRunV2.identifier,
        entities: [
            Entity<OutRunV2.Workout>(OutRunV2.Workout.identifier),
            Entity<OutRunV2.RouteDataSample>(OutRunV2.RouteDataSample.identifier)
        ],
        versionLock: [
            OutRunV2.RouteDataSample.identifier: [0x865fb73f2cdbf5f7, 0x322dae8d9552dfd8, 0x8c36786459eb5f29, 0xad1726d869fe374d],
            OutRunV2.Workout.identifier: [0x90b4ea34c3fa02ba, 0xd0fc71464bbbc8bf, 0xe102925a95892881, 0x203a9cb9289fd3a7]
        ]
    )
    static let mappingProvider = CustomSchemaMappingProvider(
        from: OutRunV1.identifier,
        to: OutRunV2.identifier,
        entityMappings: [
            .transformEntity(
                sourceEntity: OutRunV1.Workout.identifier,
                destinationEntity: OutRunV2.Workout.identifier,
                transformer: { (sourceObject: CustomSchemaMappingProvider.UnsafeSourceObject, createDestinationObject: () -> CustomSchemaMappingProvider.UnsafeDestinationObject) in
                
                    let destinationObject = createDestinationObject()
                    
                    destinationObject["isRace"] = false
                    destinationObject["isUserModified"] = false
                    destinationObject["comment"] = nil
                    
                    destinationObject.enumerateAttributes { (attribute, sourceAttribute) in
                        if let sourceAttribute = sourceAttribute {
                            destinationObject[attribute] = sourceObject[sourceAttribute]
                        }
                    }
                }
            ),
            .transformEntity(
                sourceEntity: OutRunV1.RouteDataSample.identifier,
                destinationEntity: OutRunV2.RouteDataSample.identifier,
                transformer: { (sourceObject: CustomSchemaMappingProvider.UnsafeSourceObject, createDestinationObject: () -> CustomSchemaMappingProvider.UnsafeDestinationObject) in
                
                    let destinationObject = createDestinationObject()
                    
                    destinationObject["horizontalAccuracy"] = 0
                    destinationObject["verticalAccuracy"] = 0
                    
                    destinationObject.enumerateAttributes { (attribute, sourceAttribute) in
                        if let sourceAttribute = sourceAttribute {
                            destinationObject[attribute] = sourceObject[sourceAttribute]
                        }
                    }
                }
            )
        ]
    )
    
    // MARK: Workout
    class Workout: CoreStoreObject {
        
        static let identifier = "Workout"
        
        let uuid = Value.Optional<UUID>("id")
        let workoutType = Value.Required<Int>("workoutType", initial: -1)
        let distance = Value.Required<Double>("distance", initial: -1)
        let startDate = Value.Required<Date>("startDate", initial: Date(timeIntervalSince1970: 0))
        let endDate = Value.Required<Date>("endDate", initial: Date(timeIntervalSince1970: 0))
        let dayIdentifier = Value.Optional<String>("dayIdentifier")
        let isRace = Value.Required<Bool>("isRace", initial: false)
        let comment = Value.Optional<String>("comment")
        let isUserModified = Value.Required<Bool>("isUserModified", initial: false)
        let burnedEnergy = Value.Optional<Double>("burnedEnergy")
        let healthKitUUID = Value.Optional<UUID>("healthKitID")
        
        let routeDataSamples = Relationship.ToManyOrdered<OutRunV2.RouteDataSample>("routeDataSamples", inverse: { $0.workout })
        
    }
    
    // MARK: Route Data Sample
    class RouteDataSample: CoreStoreObject {
        
        static let identifier = "RouteDataSample"
        
        let uuid = Value.Optional<UUID>("id")
        let timestamp = Value.Required<Date>("timestamp", initial: Date(timeIntervalSince1970: 0))
        let latitude = Value.Required<Double>("latitude", initial: -1)
        let longitude = Value.Required<Double>("longitude", initial: -1)
        let altitude = Value.Required<Double>("altitude", initial: -1)
        let horizontalAccuracy = Value.Required<Double>("horizontalAccuracy", initial: 0)
        let verticalAccuracy = Value.Required<Double>("verticalAccuracy", initial: 0)
        let speed = Value.Required<Double>("speed", initial: -1)
        let direction = Value.Required<Double>("direction", initial: -1)
        
        let workout = Relationship.ToOne<OutRunV2.Workout>("workout")
        
    }
    
}
