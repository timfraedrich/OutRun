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

public protocol WorkoutProtocol: Identifiable, Equatable {
    
    associatedtype WorkoutHeartRateDataSampleType: WorkoutHeartRateDataSampleProtocol
    associatedtype WorkoutRouteDataSampleType: WorkoutRouteDataSampleProtocol
    associatedtype WorkoutPauseType: WorkoutPauseProtocol
    associatedtype WorkoutEventType: WorkoutEventProtocol
    associatedtype SyncServiceMappingType: SyncServiceMappingProtocol
    
    var id: UUID { get }
    var type: WorkoutType { get }
    /// - note: Distance is provided in metres.
    var distance: Double { get }
    var startDate: Date { get }
    var endDate: Date? { get }
    /// - note: Energy is provided in joules, if nil no energy was recorded.
    var energy: Double? { get }
    /// - note: Repetitions can be steps or cycle strokes depending on the workout type.
    var repetitions: Int? { get }
    var isRace: Bool { get }
    var name: String? { get }
    var comment: String? { get }
    var creationDate: Date { get }
    var lastEditDate: Date { get }
    var source: WorkoutSource { get }
    var heartRates: [WorkoutHeartRateDataSampleType] { get }
    var route: [WorkoutRouteDataSampleType] { get }
    var pauses: [WorkoutPauseType] { get }
    var events: [WorkoutEventType] { get }
    var serviceMappings: [SyncServiceMappingType] { get }
}

public extension WorkoutProtocol {
    
    func serviceMapping(for identifier: String) -> SyncServiceMappingType? {
        serviceMappings.first { $0.serviceIdentifier == identifier }
    }
}
