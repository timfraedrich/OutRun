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
import OutRunCore

extension RawWorkout {
    
    init(from workout: LegacyRawDataModelV1.Workout) {
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(legacyRawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: LegacyMigrationHelper.convertKcalToJoules(workout.burnedEnergy),
            repetitions: nil,
            isRace: false,
            name: nil,
            comment: nil,
            creationDate: workout.endDate,
            lastEditDate: workout.endDate,
            source: .native,
            heartRates: [],
            route: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: [],
            events: [],
            serviceMappings: LegacyMigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID, lastEditDate: workout.endDate)
        )
    }
    
    init(from workout: LegacyRawDataModelV2.Workout) {
        let lastEditDate = workout.endDate.addingTimeInterval(workout.isUserModified ? 1 : 0)
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(legacyRawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: LegacyMigrationHelper.convertKcalToJoules(workout.burnedEnergy),
                    repetitions: nil,
            isRace: workout.isRace,
            name: nil,
            comment: workout.comment,
            creationDate: workout.endDate,
            lastEditDate: lastEditDate,
            source: .native,
            heartRates: [],
            route: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: [],
            events: [],
            serviceMappings: LegacyMigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID, lastEditDate: lastEditDate)
        )
    }
    
    init(from workout: LegacyRawDataModelV3.Workout) {
        let lastEditDate = workout.endDate.addingTimeInterval(workout.isUserModified ? 1 : 0)
        let pauseEvents = workout.workoutEvents.compactMap { workoutEvent -> Calculation.PauseEvent? in
            guard let pauseEventType = Calculation.PauseEventType(legacyEventType: .init(rawValue: workoutEvent.eventType))
            else { return nil }
            return .init(date: workoutEvent.startDate, type: pauseEventType)
        }
        self.init(
            id: workout.uuid ?? UUID(),
            type: .init(legacyRawValue: workout.workoutType),
            distance: workout.distance,
            startDate: workout.startDate,
            endDate: workout.endDate,
            energy: workout.burnedEnergy.map(LegacyMigrationHelper.convertKcalToJoules),
                    repetitions: workout.steps,
            isRace: workout.isRace,
            name: nil,
            comment: workout.comment,
            creationDate: workout.endDate,
            lastEditDate: lastEditDate,
            source: .native,
            heartRates: workout.heartRates.map(RawWorkoutHeartRateDataSample.init),
            route: workout.locations.map(RawWorkoutRouteDataSample.init),
            pauses: Calculation.calculatePauses(from: pauseEvents, workoutStart: workout.startDate, workoutEnd: workout.endDate),
            events: workout.workoutEvents.compactMap(RawWorkoutEvent.init),
            serviceMappings: LegacyMigrationHelper.serviceMappingsFromHealthKitUUID(workout.healthKitUUID, lastEditDate: lastEditDate)
        )
    }
}
