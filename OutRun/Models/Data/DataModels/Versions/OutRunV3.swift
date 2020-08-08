//
//  OutRunV3.swift
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
import Foundation

enum OutRunV3 {
    
    static let identifier = "OutRunV3"
    static let schema = CoreStoreSchema(
        modelVersion: OutRunV3.identifier,
        entities: [
            Entity<OutRunV3.Workout>(OutRunV3.Workout.identifier),
            Entity<OutRunV3.WorkoutEvent>(OutRunV3.WorkoutEvent.identifier),
            Entity<OutRunV3.WorkoutRouteDataSample>(OutRunV3.WorkoutRouteDataSample.identifier),
            Entity<OutRunV3.WorkoutHeartRateDataSample>(OutRunV3.WorkoutHeartRateDataSample.identifier),
            Entity<OutRunV3.Event>(OutRunV3.Event.identifier)
        ],
        versionLock: [
            OutRunV3.Workout.identifier: [0x27b6ac6afe69ba23, 0x50bf0fbb49d9884e, 0x9eaa379157c43d32, 0x752e14987c12cdcb],
            OutRunV3.WorkoutEvent.identifier: [0xc8b4bcf7f34100da, 0x67200344c2f3739d, 0xa56af4887eeceff8, 0xd8b0a9428219090],
            OutRunV3.WorkoutRouteDataSample.identifier: [0x8fb3f3add05348dc, 0xaf69cdd28c67537, 0xeda9c05c619958f, 0x62c61c5f0f6a8978],
            OutRunV3.WorkoutHeartRateDataSample.identifier: [0x2d847ce2c9e2d59a, 0x93983df8613a51d3, 0x8c53679540e541, 0xbc184a9bacf65f72],
            OutRunV3.Event.identifier: [0x8bc19058de8406f1, 0x4c9ab406f7d1eb5c, 0x7c3d5afd97f2c925, 0xd53b84436cc6cdb0]
        ]
    )
    static let mappingProvider = CustomSchemaMappingProvider(
        from: OutRunV2.identifier,
        to: OutRunV3.identifier,
        entityMappings: [
            .transformEntity(
                sourceEntity: OutRunV2.Workout.identifier,
                destinationEntity: OutRunV3.Workout.identifier,
                transformer: { (sourceObject: CustomSchemaMappingProvider.UnsafeSourceObject, createDestinationObject: () -> CustomSchemaMappingProvider.UnsafeDestinationObject) in
                
                    let destinationObject = createDestinationObject()
                    
                    destinationObject["steps"] = nil
                    
                    destinationObject.enumerateAttributes { (attribute, sourceAttribute) in
                        if let sourceAttribute = sourceAttribute {
                            destinationObject[attribute] = sourceObject[sourceAttribute]
                        }
                    }
                }
            ),
            .insertEntity(destinationEntity: OutRunV3.WorkoutEvent.identifier),
            .transformEntity(
                sourceEntity: OutRunV2.RouteDataSample.identifier,
                destinationEntity: OutRunV3.WorkoutRouteDataSample.identifier,
                transformer: { (sourceObject: CustomSchemaMappingProvider.UnsafeSourceObject, createDestinationObject: () -> CustomSchemaMappingProvider.UnsafeDestinationObject) in
                
                    let destinationObject = createDestinationObject()
                    destinationObject.enumerateAttributes { (attribute, sourceAttribute) in
                        if let sourceAttribute = sourceAttribute {
                            destinationObject[attribute] = sourceObject[sourceAttribute]
                        }
                    }
                }
            ),
            .insertEntity(destinationEntity: OutRunV3.WorkoutHeartRateDataSample.identifier),
            .insertEntity(destinationEntity: OutRunV3.Event.identifier)
        ]
    )
    
    // MARK: Workout
    class Workout: CoreStoreObject {
        
        static let identifier = "Workout"
        
        let uuid = Value.Optional<UUID>("id")
        let workoutType = Value.Required<Int>("workoutType", initial: -1)
        let distance = Value.Required<Double>("distance", initial: -1)
        let steps = Value.Optional<Int>("steps")
        let startDate = Value.Required<Date>("startDate", initial: .init(timeIntervalSince1970: 0))
        let endDate = Value.Required<Date>("endDate", initial: .init(timeIntervalSince1970: 0))
        let burnedEnergy = Value.Optional<Double>("burnedEnergy")
        let isRace = Value.Required<Bool>("isRace", initial: false)
        let comment = Value.Optional<String>("comment")
        let isUserModified = Value.Required<Bool>("isUserModified", initial: false)
        let healthKitUUID = Value.Optional<UUID>("healthKitID")
        
        let ascendingAltitude = Value.Required<Double>("ascendingAltitude", initial: 0, isTransient: true, customGetter: DataModelValueGetters.ascendingAltitude)
        let descendingAltitude = Value.Required<Double>("descendingAltitude", initial: 0, isTransient: true, customGetter: DataModelValueGetters.descendingAltitude)
        let activeDuration = Value.Required<Double>("activeDuration", initial: 0, isTransient: true, customGetter: DataModelValueGetters.activeDuration)
        let pauseDuration = Value.Required<Double>("pauseDuration", initial: 0, isTransient: true, customGetter: DataModelValueGetters.pauseDuration)
        let dayIdentifier = Value.Required<String>("dayIdentifier", initial: "", isTransient: true, customGetter: DataModelValueGetters.dayIdentifier)
        
        let heartRates = Relationship.ToManyOrdered<OutRunV3.WorkoutHeartRateDataSample>("heartRates", inverse: { $0.workout })
        let routeData = Relationship.ToManyOrdered<OutRunV3.WorkoutRouteDataSample>("routeData", inverse: { $0.workout }, renamingIdentifier: "routeDataSamples")
        let workoutEvents = Relationship.ToManyOrdered<OutRunV3.WorkoutEvent>("workoutEvents", inverse: { $0.workout })
        let events = Relationship.ToManyUnordered<OutRunV3.Event>("events", inverse: { $0.workouts })
        
    }
    
    // MARK: Workout Event
    class WorkoutEvent: CoreStoreObject {
        
        static let identifier = "WorkoutEvent"
        
        let uuid = Value.Optional<UUID>("id")
        let eventType = Value.Required<Int>("eventType", initial: 0)
        let startDate = Value.Required<Date>("startDate", initial: .init(timeIntervalSince1970: 0))
        let endDate =  Value.Required<Date>("endDate", initial: .init(timeIntervalSince1970: 0))
        
        let duration = Value.Required<Double>("duration", initial: 0, isTransient: true, customGetter: DataModelValueGetters.duration)
        
        let workout = Relationship.ToOne<OutRunV3.Workout>("workout")
        
    }
    
    // MARK: Route Data Sample
    class WorkoutRouteDataSample: CoreStoreObject {
        
        static let identifier = "WorkoutRouteDataSample"
        
        let uuid = Value.Optional<UUID>("id")
        let timestamp = Value.Required<Date>("timestamp", initial: .init(timeIntervalSince1970: 0))
        let latitude = Value.Required<Double>("latitude", initial: -1)
        let longitude = Value.Required<Double>("longitude", initial: -1)
        let altitude = Value.Required<Double>("altitude", initial: -1)
        let horizontalAccuracy = Value.Required<Double>("horizontalAccuracy", initial: 0)
        let verticalAccuracy = Value.Required<Double>("verticalAccuracy", initial: 0)
        let speed = Value.Required<Double>("speed", initial: -1)
        let direction = Value.Required<Double>("direction", initial: -1)
        
        let workout = Relationship.ToOne<OutRunV3.Workout>("workout")
        
    }
    
    // MARK: Workout Heart Rate Data Sample
    class WorkoutHeartRateDataSample: CoreStoreObject {
        
        static let identifier = "WorkoutHeartRateSample"
        
        let uuid = Value.Optional<UUID>("id")
        let heartRate = Value.Required<Double>("heartRate", initial: 0)
        let timestamp = Value.Required<Date>("timestamp", initial: .init(timeIntervalSince1970: 0))
        
        let workout = Relationship.ToOne<OutRunV3.Workout>("workout")
        
    }
    
    class Event: CoreStoreObject {
        
        static let identifier = "Event"
        
        let uuid = Value.Optional<UUID>("id")
        let title = Value.Required<String>("eventTitle", initial: "")
        let comment = Value.Optional<String>("comment")
        let startDate = Value.Optional<Date>("startDate", isTransient: true, customGetter: DataModelValueGetters.startDate)
        let endDate = Value.Optional<Date>("endDate", isTransient: true, customGetter: DataModelValueGetters.endDate)
        
        let workouts = Relationship.ToManyUnordered<OutRunV3.Workout>("workouts")
        
    }
    
}
