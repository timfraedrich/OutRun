//
// OutRun
// Copyright (C) 2025 Tim Fraedrich
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see https://www.gnu.org/licenses/.
//

import Foundation

public struct RawWorkout: Codable, Sendable, WorkoutProtocol {
    
    public var id: UUID
    public var type: WorkoutType
    public var distance: Double
    public var startDate: Date
    public var endDate: Date?
    public var energy: Double?
    public var repetitions: Int?
    public var isRace: Bool
    public var name: String?
    public var comment: String?
    public var creationDate: Date
    public var lastEditDate: Date
    public var source: WorkoutSource
    
    public var heartRates: [RawWorkoutHeartRateDataSample]
    public var route: [RawWorkoutRouteDataSample]
    public var pauses: [RawWorkoutPause]
    public var events: [RawWorkoutEvent]
    public var serviceMappings: [RawSyncServiceMapping]
    
    public init(
        id: UUID,
        type: WorkoutType,
        distance: Double,
        startDate: Date,
        endDate: Date?,
        energy: Double?,
        repetitions: Int?,
        isRace: Bool,
        name: String?,
        comment: String?,
        creationDate: Date,
        lastEditDate: Date,
        source: WorkoutSource,
        heartRates: [RawWorkoutHeartRateDataSample] = [],
        route: [RawWorkoutRouteDataSample] = [],
        pauses: [RawWorkoutPause] = [],
        events: [RawWorkoutEvent] = [],
        serviceMappings: [RawSyncServiceMapping] = []
    ) {
        self.id = id
        self.type = type
        self.distance = distance
        self.startDate = startDate
        self.endDate = endDate
        self.energy = energy
        self.repetitions = repetitions
        self.isRace = isRace
        self.name = name
        self.comment = comment
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate
        self.source = source
        self.heartRates = heartRates
        self.route = route
        self.pauses = pauses
        self.events = events
        self.serviceMappings = serviceMappings
    }
    
    public init(workout: any WorkoutProtocol) {
        self.init(
            id: workout.id,
            type: workout.type,
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: workout.energy,
            repetitions: workout.repetitions,
            isRace: workout.isRace,
            name: workout.name,
            comment: workout.comment,
            creationDate: workout.creationDate,
            lastEditDate: workout.lastEditDate,
            source: workout.source,
            heartRates: workout.heartRates.map(RawWorkoutHeartRateDataSample.init).sorted(using: SortDescriptor(\.timestamp)),
            route: workout.route.map(RawWorkoutRouteDataSample.init).sorted(using: SortDescriptor(\.timestamp)),
            pauses: workout.pauses.map(RawWorkoutPause.init).sorted(using: SortDescriptor(\.startDate)),
            events: workout.events.map(RawWorkoutEvent.init).sorted(using: SortDescriptor(\.timestamp)),
            serviceMappings: workout.serviceMappings.map(RawSyncServiceMapping.init).sorted(using: SortDescriptor(\.externalId))
        )
    }
}
