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
import SwiftData

@Model
public class Workout: WorkoutProtocol {
    
    @Attribute(.unique, .preserveValueOnDeletion) public private(set) var id: UUID
    
    public private(set) var rawType: WorkoutType.RawValue
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
    @Attribute(.preserveValueOnDeletion) public private(set) var rawSource: WorkoutSource.RawValue
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutRouteDataSample.workout) public var route: [WorkoutRouteDataSample] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutHeartRateDataSample.workout) public var heartRates: [WorkoutHeartRateDataSample] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutPause.workout) public var pauses: [WorkoutPause] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEvent.workout) public var events: [WorkoutEvent] = []
    @Relationship(deleteRule: .cascade, inverse: \SyncServiceMapping.workout) public var serviceMappings: [SyncServiceMapping] = []
    
    public var type: WorkoutType {
        get { .init(rawValue: rawType) }
        set { rawType = newValue.rawValue }
    }
    
    public var source: WorkoutSource {
        get { .init(rawValue: rawSource) }
        set { rawSource = newValue.rawValue }
    }
    
    public init(
        id: UUID = .init(),
        type: WorkoutType,
        distance: Double,
        startDate: Date,
        endDate: Date?,
        energy: Double?,
        repetitions: Int?,
        isRace: Bool,
        name: String?,
        comment: String? = nil,
        creationDate: Date,
        lastEditDate: Date? = nil,
        source: WorkoutSource
    ) {
        self.id = id
        self.rawType = type.rawValue
        self.distance = distance
        self.startDate = startDate
        self.endDate = endDate
        self.energy = energy
        self.repetitions = repetitions
        self.isRace = isRace
        self.name = name
        self.comment = comment
        self.creationDate = creationDate
        self.lastEditDate = lastEditDate ?? creationDate
        self.rawSource = source.rawValue
    }
    
    /// - note: this initializer leaves out any kind of samples. Samples must be inserted into the context and linked manually.
    public convenience init(from workout: any WorkoutProtocol) {
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
            source: workout.source
        )
    }
}
